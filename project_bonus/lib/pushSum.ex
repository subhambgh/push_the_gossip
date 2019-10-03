  defmodule PushSum do
  use GenServer

  @node_registry_name :node_registry
  @wait_time 100

  def start_link(process) do
    GenServer.start_link(__MODULE__, process, name: via_tuple(process.name))
  end

  # registry lookup handler
  defp via_tuple(name), do: {:via, Registry, {@node_registry_name, name}}

  def whereis(name) do
    case Registry.lookup(@node_registry_name, name) do
      [{pid, _}] -> pid
      [] -> nil
      end
    end

  @impl true
  def init(process) do
    adj_list =
      if !Map.has_key?(process, :mapOfNeighbours) do
        AdjacencyHelper.getAdjList(process.topology,process.numNodes,process.name,process.nodeList)
      else
        AdjacencyHelper.getAdjListForRand2DAndHoneycombs(process.topology,process.name,process.nodeList,process.mapOfNeighbours,process.numbering)
      end
    count = 0
    {:ok, {process.s, process.w, count, process.name, adj_list}}
  end

  def handle_cast({:send, {received_s, received_w}}, {s, w, count, my_name, adj_list}) do
    if adj_list !=nil && adj_list != []  do
      randomNeighbour = Enum.random(adj_list)
      randomNeighbourPid = whereis(randomNeighbour)
      if randomNeighbourPid != nil && Process.alive?randomNeighbourPid  do
        GenServer.cast(randomNeighbourPid, {:receive, {received_s, received_s}})
      else
        adj_list = List.delete(adj_list,randomNeighbour)
        GenServer.cast(self(),{:update_adjList,adj_list})
        GenServer.cast(self(), {:send, {received_s, received_w}})
      end
    else
      #complecated scenerio
    end

    {:noreply, {s, w, count, my_name, adj_list}}
  end


  # this is the receive
  @impl true
  def handle_cast({:receive, {received_s, received_w}}, {s, w, count, my_name, adj_list}) do
    # IO.puts("#{inspect(self())} #{received_s} #{received_w} #{count}")
    old_ratio = s / w
    s = received_s + s
    w = received_w + w
    new_ratio = s / w
    s = s / 2
    w = w / 2
    change = abs(old_ratio - new_ratio)
    count = if change > :math.pow(10, -10), do: 0, else: count + 1
    #IO.puts("#{inspect my_name} #{change} #{count}")
    if count >= 3 do
      GenServer.cast(PushTheGossip.Convergence,{:i_heard_it, my_name})
      # if it has steady change i.e., when count =3
      # send rumor to someone and kill urself
      # implement it like, start any actor that hasn't received message for like 100 ms
      Process.exit(self(), :normal)
      {:noreply, {s, w, count, my_name, adj_list}}
    else
        GenServer.cast(self(), {:send, {s, w}})
        #################### starting periodic callback here #################
        Process.send_after(self(), :tick, @wait_time)
        ######################################################################
      {:noreply, {s, w, count, my_name, adj_list}}
    end
  end

  @impl true
  def handle_cast({:update_adjList, updatedAdjList}, {s, w, count, my_name, adj_list}) do
    #{:noreply, {s, w, count, my_name, new_neighbours}}
    if updatedAdjList != [] || updatedAdjList != nil  do
      {:noreply,{s, w,count,my_name,updatedAdjList}}
    else
      Process.exit(self(),:normal)
      {:noreply,{s, w,count,my_name,adj_list}}
    end
  end

  ###################################################################
  ## sends iff 1. it has received atleast once
  ############ &2. it hasn't received a message for a time = @wait_time
  ####################################################################
  @impl true
  def handle_info(:tick, {s, w, count, my_name, adj_list}) do
    GenServer.cast(self(), {:send, {s, w}})
    Process.send_after(self(), :tick, @wait_time)
    {:noreply, {s, w, count, my_name, adj_list}}
  end

end
