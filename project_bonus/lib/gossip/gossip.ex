defmodule Gossip do
  use GenServer

  def start_link(process) do
    GenServer.start_link(__MODULE__,%{})
  end

  @impl true
  def init(process) do
    count=0
    #this adj_list stores only his adjacency list - meaning his neighbour
    ############ remember: nodeList can be simple list of nodes
                          #or can be (nodes and neighbour) map in case of 3d and Honeycomb
    adj_list =
      if process.numbering ==nil do
        AdjacencyHelper.getAdjList(process.topology,process.numNodes,process.name,process.nodeList)
      else
        AdjacencyHelper.getAdjList(process.topology,process.numNodes,process.numbering,process.nodeList)
      end
    {:ok, {count, process.name,adj_list,process.nodeList}}
  end

  def gossip(name,adj_list) do
    if adj_list !=nil && adj_list != []  do
      randomNeighbour = Enum.random(adj_list)
      #IO.puts("randomNeighbour=#{inspect randomNeighbour}")
      randomNeighbourPid = GenServer.call(KV.Registry,{:lookup,randomNeighbour})
      #self may come in case of gossip full and line
      if randomNeighbourPid != self() && Process.alive?randomNeighbourPid do
        #IO.puts("#{inspect name} sending to #{inspect randomNeighbour}")
        GenServer.cast(randomNeighbourPid, {:transrumor, "rumor"})
        gossip(name,adj_list)
      else
        #remove self/dead node from adj_list
        adj_list = List.delete(adj_list,randomNeighbour)
        gossip(name,adj_list)
      end
    else
      #has an empty adjacency list - meaning no neighbour
      Process.exit(self(),:normal)
    end
  end

  # this is the receive
  @impl true
  def handle_cast({:transrumor, rumor}, {count,name,adj_list,nodeList}) do
    #IO.puts("received by#{name}")
    if count == 0 do
      spawn_link(__MODULE__,:gossip,[name,adj_list])
      GenServer.call(PushTheGossip.Convergence, {:i_heard_it_remove_me,name})
      {:noreply, {count + 1,name,adj_list,nodeList}}
    else
      if count < 10 do
        {:noreply, {count + 1,name,adj_list,nodeList}}
      else
        ###remove him from others nodeList
        # Enum.each(0..length(adj_list)-1, fn i ->
        #   neighbourPid = GenServer.call(KV.Registry,{:lookup,Enum.at(adj_list,i)})
        #   #if Process.alive?neighbourPid do
        #       _ = GenServer.call(neighbourPid,{:update_neighbours,name})
        #   #end
        # end)
        Process.exit(self(),:normal)
        {:noreply, {count + 1,name,adj_list,nodeList}}
      end
    end
  end


  #deletes the neighbour with name = neighbourDone
  #but the gossip function doesn't use  nodeList from state
  #so no use for gossip full
  @impl true
  def handle_call({:update_neighbours,neighbourDone},_from,{count,name,adj_list,nodeList}) do
    if adj_list != [] || adj_list != nil  do
      adj_list = List.delete(adj_list,neighbourDone)
      {:reply,name,{count,name,adj_list,nodeList}}
    else
      {:reply,name,{count,name,adj_list,nodeList}}
    end
  end

  @impl true
  def handle_info(:kill_me_pls, state) do
    # {:stop, reason, new_state}
    {:stop, :normal, state}
  end

  @impl true
  def terminate(_, _state) do
    #IO.inspect("Look! I'm dead.")
  end
end
