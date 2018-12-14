defmodule ElevatorState do
  use GenServer
  @server_name :ElevatorState
  

  # GenServer builtins ------------------------------
  def start_link() do
    start_link([{:name, @server_name}])
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, State.state(:up, 0)}
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
    state = %{state | floor: floor}
    if OrderServer.handleable_orders_exist(:OrderServer, state) do
      ElevatorInterface.set_motor_direction(:ElevatorInterface, :stop)
      IO.puts "opening doors"
      ElevatorInterface.set_door_open_light(:ElevatorInterface, :on)
      :timer.sleep 3000
      IO.puts "closing doors"
      ElevatorInterface.set_door_open_light(:ElevatorInterface, :off)
      case recursive_remove_orders(state) do
        :nil ->
          IO.puts "no more orders. going idle"
          {:noreply, %{state | direction: :idle}}
        headed_to ->
          IO.write "handling new order: "
          IO.inspect headed_to
          direction = move_towards_order(state, headed_to)
          {:noreply, %{state | direction: direction}}
      end
    else
      headed_to = hd OrderServer.get_orders_prioritized(:OrderServer, state)
      {:noreply, %{state | direction: move_towards_order(state, headed_to)}}
    end
  end

  def handle_cast(:wake, state)do
    reached_floor(:ElevatorState, state.floor)
    {:noreply, state}
  end

  # Helper functions ----------------------------------------------

  def recursive_remove_orders state do
    case OrderServer.get_orders_prioritized(:OrderServer, state) do
      [] ->
        :nil
      [order | _] -> 
        if order.floor == state.floor do
          OrderServer.remove_order(:OrderServer, order)
          :timer.sleep(100)
          IO.write "popped order "
          IO.inspect order 
          recursive_remove_orders(state)
        else
          order
        end
    end
  end


  def move_towards_order(state = %State{}, order = %Order{}) do
    if order.floor > state.floor do 
      ElevatorInterface.set_motor_direction(:ElevatorInterface, :up)
      :up
    else
      ElevatorInterface.set_motor_direction(:ElevatorInterface, :down)
      :down
    end
  end
end
