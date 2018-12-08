defmodule Elevatorstate do
  use GenServer
  @server_name :Elevatorstate
  

  # GenServer builtins ------------------------------
  def start_link() do
    start_link([{:name, @server_name}])
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %State{floor: 0, direction: :stop, doors_open: false}}
  end


  # API ------------------------------
  def reached_floor(server, floor) do
    GenServer.cast(server, {:reached_floor, floor})
  end

  def wake(server) do
    IO.puts "waking elevator"
    GenServer.cast(server, :wake)
  end

  # Casts and Calls ------------------------------------------------

  def handle_cast({:reached_floor, floor}, state) do
    target_order = Orderserver.get_priority_order(:Orderserver, state)
    state = %{state | floor: floor}
    cond do
      (state.floor != target_order.floor) and (state.direction != :stop) ->
        IO.write "passing floor "
        IO.inspect floor 
        {:noreply, state}
      true ->
        ElevatorInterface.set_motor_direction(:ElevatorInterface, :stop)
        IO.puts "opening doors"
        :timer.sleep(3000)
        IO.puts "closing doors"
        target_floor = recursive_remove_orders(state)
        cond do
          target_floor == :nil ->
            IO.puts "No more orders. Stopping"
            ElevatorInterface.set_motor_direction(:ElevatorInterface, :stop)
            {:noreply, %{state | direction: :stop}}
          target_floor.floor > state.floor ->
            IO.write "Moving up to "
            IO.inspect target_floor.floor
            ElevatorInterface.set_motor_direction(:ElevatorInterface, :up)
            {:noreply, %{state | direction: :up}}
          target_floor.floor < state.floor ->
            IO.write "Moving down to "
            IO.inspect target_floor.floor
            ElevatorInterface.set_motor_direction(:ElevatorInterface, :down)
            {:noreply, %{state | direction: :down}}
        end
    end
  end

  def handle_cast(:wake, state) do
    reached_floor(:Elevatorstate, state.floor)
    {:noreply, state}
  end


  # Helper functions ----------------------------------------------

  def recursive_remove_orders state do
    target_order = Orderserver.get_priority_order(:Orderserver, state)
    cond do
      target_order == :nil ->
        :nil
      target_order.floor == state.floor ->
        Orderserver.remove_order(:Orderserver, target_order)
        IO.write "popped order "
        IO.inspect target_order 
        recursive_remove_orders(state)
      true ->
        target_order
    end
  end
end


defmodule Elevator_test do
  def stuff do
    Orderserver.start_link
    Elevatorstate.start_link
    Orderserver.add_order(:Orderserver, %Order{floor: 2, order_type: :hall_up})
    Orderserver.add_order(:Orderserver, %Order{floor: 2, order_type: :cab})
    Orderserver.add_order(:Orderserver, %Order{floor: 2, order_type: :hall_down})
    Orderserver.add_order(:Orderserver, %Order{floor: 3, order_type: :hall_up})
    Orderserver.add_order(:Orderserver, %Order{floor: 0, order_type: :hall_up})
  end
end
