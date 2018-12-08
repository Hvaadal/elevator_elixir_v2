defmodule PollingServer do
  use GenServer
  @server_name :PollingServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [{:name, @server_name}])
  end

  def init(:ok) do
    Enum.map(ScanAlgorithm.all_orders(), fn x -> Process.spawn(Poller, :poller, [x, :off], [])end)
    Process.spawn(FloorPoller, :poller, [:idle], [])
    {:ok, []}
  end

  def button_pressed(pid, order = %Order{}) do 
    GenServer.cast pid, {:button_pressed, order} 
  end

  def reached_floor(pid, floor) do 
    GenServer.cast pid, {:reached_floor, floor}
  end

  def handle_cast {:button_pressed, order}, [] do
    OrderServer.add_order(:OrderServer, order)
    {:noreply, []}
  end

  def handle_cast {:reached_floor, _floor}, [] do
    #Elevatorstate.reached_floor(:Elevatorstate, floor)
    {:noreply, []}
  end
end


defmodule Poller do
  def poller(order = %Order{} , :off) do
    :timer.sleep(200)
    button_state = ElevatorInterface.get_order_button_state(:ElevatorInterface, order.floor, order.type)
    state_map = %{1 => :transient, 0 => :off}
    poller(order, state_map[button_state])
  end

  def poller(order = %Order{} , :transient) do
    PollingServer.button_pressed(:PollingServer, order)
    poller(order, :on)
  end
  
  def poller(order = %Order{} , :on) do
    :timer.sleep(200)
    button_state = ElevatorInterface.get_order_button_state(:ElevatorInterface, order.floor, order.type)
    state_map = %{1 => :on, 0 => :off}
    poller(order, state_map[button_state])
  end
end


defmodule FloorPoller do
  def poller(:idle) do
    :timer.sleep(200)
    case ElevatorInterface.get_floor_sensor_state(:ElevatorInterface) do
      :between_floors ->
        poller(:between_floors)
      _anything_else ->
        poller(:idle)
    end
  end

  def poller(:between_floors) do
    :timer.sleep(200)
    poller(ElevatorInterface.get_floor_sensor_state(:ElevatorInterface))
  end
  
  def poller(floor) do
    PollingServer.reached_floor(:PollingServer, floor)
    poller(:idle)
  end
end
