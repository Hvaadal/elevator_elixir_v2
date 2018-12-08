defmodule ElevatorElixir do
  def init do
    OrderServer.start_link
    PollingServer.start_link
    ElevatorInterface.start
  end
end
