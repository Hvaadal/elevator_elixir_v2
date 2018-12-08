defmodule OrderServer do
  use GenServer
  @server_name :OrderServer
  

  # GenServer builtins ------------------------------
  def start_link() do
    start_link([{:name, @server_name}])
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, []}
  end


  # API ------------------------------
  def add_order(server, order = %Order{}) do
    IO.write "order added"
    IO.inspect order
    GenServer.cast(server, {:add_order, order})
  end

  def remove_order(server, order = %Order{}) do
    GenServer.cast(server, {:remove_order, order})
  end

  def get_orders_prioritized(server, state = %State{}) do
    GenServer.call(server, {:get_orders_prioritized, state})
  end

  # Casts and calls ----------------------------------------

  def handle_call({:get_orders_prioritized, _state}, _from, []) do
    {:reply, :nil, []}
  end

  def handle_call({:get_orders_prioritized, state}, _from, order_list) do
    {:reply, ScanAlgorithm.prioritize_orders(state, order_list), order_list}
  end

  def handle_cast({:remove_order, order}, order_list) do
    ElevatorInterface.set_order_button_light(:ElevatorInterface, order.type, order.floor, :off)
    {:noreply, List.delete(order_list, order)}
  end

  def handle_cast({:add_order, order}, []) do
    ElevatorInterface.set_order_button_light(:ElevatorInterface, order.type, order.floor, :on)
    {:noreply, [order]}
  end 

  def handle_cast({:add_order, order}, order_list) do
    ElevatorInterface.set_order_button_light(:ElevatorInterface, order.type, order.floor, :on)
    {:noreply, Enum.uniq([order | order_list])}
  end 
end

