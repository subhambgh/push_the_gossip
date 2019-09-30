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
    converged_or_not = 0
    {:ok, {time_start, numNodes, count, list_of_nodes, converged_or_not}}
  end

  def handle_call({:getState},_from ,{time_start,  numNodes, count, list_of_nodes, converged_or_not}) do
    {:reply,list_of_nodes ,{time_start,  numNodes, count, list_of_nodes, converged_or_not}}
  end

  # def handle_cast({:time_start, [value_time, value_numNodes] }, {time_start,  numNodes, count, list_of_nodes, converged_or_not}) do
  #   time_start = value_time
  #   numNodes = value_numNodes
  #   {:noreply, {time_start,  numNodes, count, list_of_nodes, converged_or_not}}
  # end

  def handle_cast({:time_start_with_list, [value_time, value_numNodes, value_list] }, {time_start,  numNodes, count, list_of_nodes, converged_or_not}) do
    time_start = value_time
    numNodes = value_numNodes
    list_of_nodes = value_list
    {:noreply, {time_start,  numNodes, count, list_of_nodes, converged_or_not}}
  end

  # def handle_call({:i_heard_it}, _from, {time_start,  numNodes, count, list_of_nodes, converged_or_not}) do
  #   new_count = count + 1
  #   if new_count >= numNodes do
  #     IO.puts("Converged! Time = #{System.system_time(:millisecond) - time_start} ms")
  #     converged_or_not = 1
  #     System.halt(1)
  #   end
  #   {:reply, {time_start,  numNodes, new_count}, {time_start,  numNodes, new_count, list_of_nodes, converged_or_not}}
  # end


  def handle_call({:i_heard_it_push}, _from, {time_start,  numNodes, count, list_of_nodes, converged_or_not}) do
    IO.puts("Converged! Time = #{System.system_time(:millisecond) - time_start} ms")
    {:reply, {time_start,  numNodes, count}, {time_start,  numNodes, count, list_of_nodes, converged_or_not}}
  end


  def handle_call({:i_heard_it_remove_me, name}, _from, {time_start,  numNodes, count, list_of_nodes, converged_or_not}) do
    new_list_of_nodes = list_of_nodes -- [name]
    #IO.puts("Not Converged #{inspect new_list_of_nodes}")
    #IO.puts("#{length(new_list_of_nodes)}")
    if length(new_list_of_nodes) <= numNodes/10 do
      converged_or_not   = 1
      IO.puts("Converged! Time = #{System.system_time(:millisecond) - time_start} ms")
      System.halt(1)
    end
    {:reply, new_list_of_nodes, {time_start,  numNodes, count, new_list_of_nodes, converged_or_not}}
  end

end
