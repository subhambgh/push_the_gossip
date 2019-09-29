defmodule PushTheGossip.Convergence do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(opts) do
    time_start = 0
    count = 0
    numNodes = -1
    {:ok, {time_start, numNodes, count}}
  end

  def handle_cast({:time_start, [value_time, value_numNodes] }, {time_start,  numNodes, count}) do
    time_start = value_time
    numNodes = value_numNodes
    {:noreply, {time_start,  numNodes, count}}
  end


  def handle_cast({:i_heard_it}, {time_start,  numNodes, count}) do
    
    new_count = count + 1
    if new_count >= numNodes do
      IO.puts("Converged! Time = #{System.system_time(:millisecond) - time_start} ms")
    end

    {:noreply, {time_start,  numNodes, new_count}}
  end

end


# defmodule PushTheGossip.Convergence do
#   use GenServer

#   def start_link(opts \\ []) do
#     GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
#   end

#   def init(opts) do
#     time_start = 0
#     count = 0
#     numNodes = -1
#     {:ok, {time_start, numNodes, count}}
#   end

#   def handle_cast({:time_start, [value_time, value_numNodes] }, {time_start,  numNodes, count}) do
#     time_start = value_time
#     numNodes = Enum.map(value_numNodes, fn {k,v} -> k end)
#     {:noreply, {time_start,  numNodes, count}}
#   end


#   def handle_cast({:i_heard_it, name}, {time_start,  numNodes, count}) do
    
#     #new_count = count + 1 
#     newNUms = numNodes -- [name]
#     #if new_count >= numNodes do
#     if length(newNUms) == 0  do
      
#       IO.puts("Converged! Time = #{System.system_time(:millisecond) - time_start} ms")
#     end

#     {:noreply, {time_start,  newNUms, count}}
#   end

# end