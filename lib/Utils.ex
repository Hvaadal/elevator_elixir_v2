defmodule State do
  @valid_directions [:down, :idle, :up]
  defstruct floor: 0, direction: :idle

  def state(direction, floor) when direction in @valid_directions do
    %State{direction: direction, floor: floor} 
  end
end

defmodule Order do
  @valid_types [:hall_down, :cab, :hall_up]
  @top_floor 3

  @enforce_keys [:type, :floor]
  defstruct [:type, :floor, :priority]

  def valid_types do
    @valid_types
  end

  def top_floor do
    @top_floor
  end

  def order(type, floor) when type in @valid_types do
    %Order{type: type, floor: floor} 
  end
    
end
