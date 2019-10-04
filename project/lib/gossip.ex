defmodule Gossip do
  use GenServer

  @node_registry_name :node_registry

  def start_link(process) do
    GenServer.start_link(__MODULE__,process, name: via_tuple(process.name))
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
    count=0
    #this adj_list stores only his adjacency list - meaning his neighbour
    ############ remember: nodeList can be simple list of nodes
                          #or can be (nodes and neighbour) map in case of 3d and Honeycomb
    adj_list =
      if !Map.has_key?(process, :mapOfNeighbours) do
        AdjacencyHelper.getAdjList(process.topology,process.numNodes,process.name,process.nodeList)
      else
        AdjacencyHelper.getAdjListForRand2DAndHoneycombs(process.topology,process.name,process.nodeList,process.mapOfNeighbours,process.numbering)
      end
      #IO.puts "#{inspect process.name} => #{inspect adj_list}"
    {:ok, {process.topology,process.numNodes,count, process.name,adj_list}}
  end

  def gossip(topology,name,numNodes,adj_list) do
    if adj_list !=nil && adj_list != []  do
      randomNeighbour =
      if(topology == "full") do
        :rand.uniform(numNodes)
      else
        Enum.random(adj_list)
      end
      randomNeighbourPid = whereis(randomNeighbour)
      if randomNeighbourPid != nil do #&& Process.alive?randomNeighbourPid
        #IO.puts("#{inspect name} sending to #{inspect randomNeighbour}")
        GenServer.cast(randomNeighbourPid, {:receive, "rumor"})
        gossip(topology,name,numNodes,adj_list)
      else
        #remove dead node from adj_list
        adj_list = List.delete(adj_list,randomNeighbour)
        #IO.puts("#{inspect adj_list}")
        GenServer.cast(self(),{:update_adjList,adj_list})
        gossip(topology,name,numNodes,adj_list)
      end
    else
      #has an empty adjacency list - meaning no neighbour
      Registry.unregister(@node_registry_name, name)
      #rocess.exit(self(),:normal)
    end
  end

  # this is the receive
  @impl true
  def handle_cast({:receive, _rumor}, {topology,numNodes,count,name,adj_list}) do
    #IO.puts("received by #{inspect name}")
    if count == 0 do
      #GenServer.cast(PushTheGossip.Convergence, {:i_heard_it,name})
      spawn_link(__MODULE__,:gossip,[topology,name,numNodes,adj_list])
      ###############
      convergence_counter = :ets.update_counter(:convergence_counter, "count", {2,1})
      #IO.puts("#{inspect convergence_counter}")
      if convergence_counter == numNodes do
        time_start = elem(Enum.at(:ets.lookup(:convergence_time, "start"),0),1)
        IO.puts "Converged in = #{inspect (System.system_time(:millisecond) - time_start) } Milliseconds"
        System.halt(1)
      end
      ###############
      {:noreply, {topology,numNodes,count + 1,name,adj_list}}
    else
      if count < 10 do
        {:noreply, {topology,numNodes,count + 1,name,adj_list}}
      else
        Registry.unregister(@node_registry_name, name)
        #Process.exit(self(),:normal)
        {:noreply, {topology,numNodes,count + 1,name,adj_list}}
      end
    end
  end

  #updates its adj_list
  @impl true
  def handle_cast({:update_adjList,updatedAdjList},{topology,numNodes,count,name,adj_list}) do
    #IO.puts("#{inspect updatedAdjList}")
    if updatedAdjList != [] || updatedAdjList != nil  do
      {:noreply,{topology,numNodes,count,name,updatedAdjList}}
    else
      #Process.exit(self(),:normal)
      {:noreply,{topology,numNodes,count,name,adj_list}}
    end
  end

  @impl true
  def handle_info(:kill_me_pls, state) do
    # {:stop, reason, new_state}
    {:stop, :normal, state}
  end
end
