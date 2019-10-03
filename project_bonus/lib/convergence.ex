defmodule PushTheGossip.Convergence do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(opts) do
    time_start = 0
    count = 0
    numNodes = -1
    remaningNodes = []
    {:ok, {time_start, numNodes, count, remaningNodes}}
  end

  def handle_call({:getState},_from ,{time_start,  numNodes, count, remaningNodes}) do
    #IO.inspect(remaningNodes)
    {:reply,{time_start,  numNodes, count, remaningNodes} ,{time_start,  numNodes, count, remaningNodes}}
  end

  ###############################  that doesn't take list of nodes #############################################
  def handle_cast({:time_start, [startTime, totalNodes] }, {time_start,  numNodes, count, remaningNodes}) do
    {:noreply, {startTime,totalNodes, 0, []}}
  end

  def handle_cast({:i_heard_it, name}, {time_start,  numNodes, count, remaningNodes}) do
    count = count+1
    #IO.puts "#{count}"
    if count >= (0.7*numNodes) do
      IO.puts("Converged! Time = #{System.system_time(:millisecond) - time_start} ms")
      System.halt(1)
    end
    {:noreply, {time_start,  numNodes, count, remaningNodes}}
  end

  ############################### for push sum that take list of nodes #############################################
  # def handle_cast({:time_start_with_list, [startTime, totalNodes, startingWithNodes] }, {time_start,  numNodes, count, remaningNodes}) do
  #   {:noreply, {startTime,totalNodes, 0, startingWithNodes}}
  # end
  #
  # def handle_call({:i_heard_it_remove_me, name}, _from, {time_start,  numNodes, count, remaningNodes}) do
  #   remaningNodes = remaningNodes -- [name]
  #   if length(remaningNodes)<=1 do
  #     IO.puts("Converged! Time = #{System.system_time(:millisecond) - time_start} ms")
  #     System.halt(1)
  #   end
  #   {:reply, 0, {time_start,  numNodes, count, remaningNodes}}
  # end
  #
  # def handle_call({:helpConvergencePushSum, name}, _from, {time_start,  numNodes, count, remaningNodes}) do
  #   if remaningNodes != [] do
  #     randomNeighbourPid = PushSum.whereis(Enum.random(remaningNodes))
  #     GenServer.cast(randomNeighbourPid, {:receive, {0, 0}})
  #   end
  #   {:reply, 0, {time_start,  numNodes, count, remaningNodes}}
  # end

end
