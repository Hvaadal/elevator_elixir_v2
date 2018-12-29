defmodule ElevatorElixir do
  def init elevator_number, port do
    PollingServer.start_link
    ElevatorInterface.start({127,0,0,1}, port)
    ElevatorInterface.set_motor_direction(:ElevatorInterface, :down)
    wait_for_reset()
    ElevatorState.start_link
    OrderServer.start_link

    ip = :os.cmd('hostname -I') |> to_string |> String.trim
    #Node.start(String.to_atom("heis"<>Integer.to_string(elevator_number)<>"@"<>ip))
    Node.start(String.to_atom("heis"<>Integer.to_string(elevator_number)<>"@127.0.0.1"))
    Node.set_cookie :zooploop
  end

  def wait_for_reset do
    :timer.sleep(300)
    case ElevatorInterface.get_floor_sensor_state(:ElevatorInterface) do
      0 -> ElevatorInterface.set_motor_direction(:ElevatorInterface, :stop)
      _ -> wait_for_reset()
    end
  end
end
