defmodule PushTheGossip.Convergence do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(opts) do
    time_start = 0
    count = 0
    numNodes = -1
    list_of_nodes = []
    {:ok, {time_start, numNodes, count, list_of_nodes}}
  end

  def handle_call({:getState},_from ,{time_start,  numNodes, count, list_of_nodes}) do
    #IO.inspect(list_of_nodes)
    {:reply,list_of_nodes ,{time_start,  numNodes, count, list_of_nodes}}
  end

  def handle_cast({:time_start_with_list, [value_time, value_numNodes, value_list] }, {time_start,  numNodes, count, list_of_nodes}) do
    time_start = value_time
    numNodes = value_numNodes
    list_of_nodes = value_list
    {:noreply, {time_start,numNodes, count, list_of_nodes}}
  end

  def handle_call({:i_heard_it_push}, _from, {time_start,  numNodes, count, list_of_nodes}) do
    IO.puts("Converged! Time = #{System.system_time(:millisecond) - time_start} ms")
    {:reply, {time_start,  numNodes, count}, {time_start,  numNodes, count, list_of_nodes}}
  end

  def handle_call({:i_heard_it_remove_me, name}, _from, {time_start,  numNodes, count, list_of_nodes}) do
    count = count+1
    new_list_of_nodes = list_of_nodes -- [name]
    #IO.puts("converzed #{inspect name} #{count}")
    #IO.puts("converzed #{inspect list_of_nodes}")
    #90 % convergence
    if length(new_list_of_nodes) <= numNodes/10 do
      IO.puts("Converged! Time = #{System.system_time(:millisecond) - time_start} ms")
      System.halt(1)
    end
    {:reply, new_list_of_nodes, {time_start,  numNodes, count, new_list_of_nodes}}
  end

end
