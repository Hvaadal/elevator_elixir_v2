defmodule Network do
  def acknowledge_order order = %Order{} do
    ElevatorInterface.set_order_button_light(:ElevatorInterface, order.type, order.floor, :on)
  end

  def remove_order order = %Order{} do
    ElevatorInterface.set_order_button_light(:ElevatorInterface, order.type, order.floor, :off)
  end

  def disconnect_node node do
    Node.disconnect node
  end

  def distribute_order = %Order{} do
     
  end
end
