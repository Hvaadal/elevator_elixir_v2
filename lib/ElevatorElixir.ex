defmodule ElevatorElixir do
  def init do
    PollingServer.start_link
    ElevatorInterface.start
    ElevatorInterface.set_motor_direction(:ElevatorInterface, :down)
    wait_for_reset()
    OrderServer.start_link
    ElevatorState.start_link
  end

  def wait_for_reset do
    :timer.sleep(300)
    case ElevatorInterface.get_floor_sensor_state(:ElevatorInterface) do
      0 -> ElevatorInterface.set_motor_direction(:ElevatorInterface, :stop)
      _ -> wait_for_reset()
    end
  end
end
