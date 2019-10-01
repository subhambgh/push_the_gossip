defmodule Gossip do
  use GenServer

  def start_link(process) do
    GenServer.start_link(__MODULE__,process)
  end

  @impl true
  def init(process) do
    count=0
    #this adj_list stores only his adjacency list - meaning his neighbour
    adj_list = AdjacencyHelper.getAdjList(process.topology,process.numNodes,process.name,process.nodeList)
    {:ok, {count, process.name,process.nodeList,adj_list}}
  end

  def gossip(name,adj_list) do
    if adj_list !=nil && adj_list != %{}  do
      randomNeighbourPid = GenServer.call(KV.Registry,{:lookup,Enum.random(adj_list)})
      #self may come in case of gossip full and line
      if randomNeighbourPid != self() && Process.alive?randomNeighbourPid do
        GenServer.cast(randomNeighbourPid, {:transrumor, "rumor"})
      end
    end
    gossip(name,adj_list)
  end

  # this is the receive
  @impl true
  def handle_cast({:transrumor, rumor}, {count,name,adj_list,nodeList}) do
    if count == 0 do
      spawn_link(__MODULE__,:gossip,[name,adj_list])
      GenServer.call(PushTheGossip.Convergence, {:i_heard_it_remove_me,name})
      {:noreply, {count + 1,name,adj_list}}
    else
      if count < 10 do
        {:noreply, {count + 1,name,adj_list,nodeList}}
      else
        ###remove him from others nodeList
        Enum.each(1..nodeList, fn i ->
          _ = GenServer.call(GenServer.call(KV.Registry,{:lookup,i}),{:update_neighbours,name})
        end)
        Process.exit(self(),:kill)
        #GenServer.call(KV.Registry, {:updateMap,name})
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
      adj_list = adj_list -- [neighbourDone]
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
    IO.inspect("Look! I'm dead.")
  end
end
