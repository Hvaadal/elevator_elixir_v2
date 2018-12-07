defmodule ScanAlgorithm do

  @top_floor Order.top_floor

  def all_orders(order_type) do
    floor_map = %{
      hall_down:  1..@top_floor,
      cab:        0..@top_floor,
      hall_up:    0..@top_floor-1
    }
    Enum.map(floor_map[order_type], fn floor -> %Order{floor: floor, type: order_type} end)
  end

  def all_orders do
    Enum.map(Order.valid_types, fn type -> all_orders type end) |> List.flatten
  end

  def dir_to_int(state = %State{}) do
    %{:down => -1, :idle => 0, :up => 1}[state.direction]
  end 

  def dir_to_int(order = %Order{}) do
    %{:hall_down => -1, :cab => 0, :hall_up => 1}[order.type]
  end 

  def distance(state = %State{}, order = %Order{}) do
    abs(state.floor - order.floor)
  end

  def can_handle_order(state = %State{floor: floor}, order = %Order{floor: floor}) do
    case order.type do
      :cab          -> true
      _hall_order   -> dir_to_int(state) == dir_to_int(order)
    end
  end

  def can_handle_order(state = %State{}, order = %Order{}) do
    false
  end

  def opposite_direction(state = %State{}) do
    %{:down => :up, :up => :down}[state.direction]
  end

  def at_apex(state = %State{}) do
    {state.floor, state.direction} in [{@top_floor, :up}, {0, :down}]
  end

  def next_state(state = %State{}) do
    if at_apex(state) do
        %State{state | direction: opposite_direction(state)}
    else
        %State{state | floor: state.floor + dir_to_int(state)}
    end
  end

  def traverse_orders(state = %State{}, order = %Order{}, jumps) do
    if can_handle_order(state, order) do
      jumps
    else
      IO.inspect state
      traverse_orders(next_state(state), order, jumps+1)
    end
  end


  def order_priority(state = %State{}, order = %Order{}) do
    case state.direction do
      :idle ->
        distance(state, order)
      _moving ->
        traverse_orders(state, order, 0)
    end
  end

  def prioritize_orders(state = %State{}, orders) do
    Enum.map(orders, fn order -> %{order | priority: order_priority(state, order)} end)
  end

end
