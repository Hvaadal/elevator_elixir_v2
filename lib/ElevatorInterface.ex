defmodule ElevatorInterface do
  use GenServer
  @call_timeout 1000
  @server_name :ElevatorInterface
  @button_map %{:hall_up => 0, :hall_down => 1, :cab => 2}
  @state_map  %{:on => 1, :off => 0}
  @direction_map %{:up => 1, :down => 255, :stop => 0}

  def start do
    start {127,0,0,1}, 15657
  end

  def start address, port do
    GenServer.start_link(__MODULE__, [address, port], [{:name, @server_name}])
  end

  def stop pid do
    GenServer.stop pid
  end

  def init [address, port] do
    {:ok, socket} =:gen_tcp.connect(address, port, [{:active, false}])
    {:ok, socket}
  end


  # User API ----------------------------------------------
  def set_motor_direction pid, direction do
    GenServer.cast pid, {:set_motor_direction, direction}
  end

  def set_order_button_light pid, button_type, floor, state do
    GenServer.cast pid, {:set_order_button_light, button_type, floor, state}
  end

  def set_floor_indicator pid, floor do
    GenServer.cast pid, {:set_floor_indicator, floor}
  end

  def set_stop_button_light pid, state do
    GenServer.cast pid, {:set_stop_button_light, state}
  end

  def set_door_open_light pid, state do
    GenServer.cast pid, {:set_door_open_light, state}
  end

  def get_order_button_state pid, floor, button_type do
    GenServer.call pid, {:get_order_button_state, floor, button_type}
  end

  def get_floor_sensor_state pid do
    GenServer.call pid, :get_floor_sensor_state
  end

  def get_stop_button_state pid do
    GenServer.call pid, :get_stop_button_state
  end

  def get_obstruction_switch_state pid do
    GenServer.call pid, :get_obstruction_switch_state
  end



  # Casts  ----------------------------------------------
  def handle_cast {:set_motor_direction, direction}, socket do
    :gen_tcp.send(socket, [1, @direction_map[direction], 0, 0])
    {:noreply, socket}
  end

  def handle_cast {:set_order_button_light, button_type, floor, state}, socket do
    :gen_tcp.send socket, [2, @button_map[button_type], floor, @state_map[state]]
    {:noreply, socket}
  end

  def handle_cast {:set_floor_indicator, floor}, socket do
    :gen_tcp.send socket, [3, floor, 0, 0]
    {:noreply, socket}
  end

  def handle_cast {:set_door_open_light, state}, socket do
    :gen_tcp.send socket, [4, @state_map[state], 0, 0]
    {:noreply, socket}
  end

  def handle_cast {:set_stop_button_light, state}, socket do
    :gen_tcp.send socket, [5, @state_map[state], 0, 0]
    {:noreply, socket}
  end



  # Calls  ----------------------------------------------
  def handle_call {:get_order_button_state, floor, order_type}, _from, socket do
    :gen_tcp.send socket, [6, @button_map[order_type], floor, 0]
    {:ok, [6, state, 0, 0]} = :gen_tcp.recv(socket, 4, @call_timeout)
    {:reply, state, socket}
  end


  def handle_call :get_floor_sensor_state, _from, socket do
    :gen_tcp.send socket, [7, 0, 0, 0] 
    button_state = case :gen_tcp.recv(socket, 4, @call_timeout) do
      {:ok, [7, 0, _, 0]} -> :between_floors
      {:ok, [7, 1, floor, 0]} -> floor
    end
    {:reply, button_state, socket}
  end

  def handle_call :get_stop_button_state, _from, socket do
    :gen_tcp.send socket, [8, 0, 0, 0] 
    button_state = case :gen_tcp.recv(socket, 4, @call_timeout) do
      {:ok, [8, 0, 0, 0]} -> :inactive
      {:ok, [8, 1, 0, 0]} -> :active
    end
    {:reply, button_state, socket}
  end

  def handle_call :get_obstruction_switch_state, _from, socket do
    :gen_tcp.send socket, [9, 0, 0, 0] 
    button_state = case :gen_tcp.recv(socket, 4, @call_timeout) do
      {:ok, [9, 0, 0, 0]} -> :inactive
      {:ok, [9, 1, 0, 0]} -> :active
    end
    {:reply, button_state, socket}
  end
end
