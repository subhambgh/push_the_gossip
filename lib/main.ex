defmodule Main do

  def periodicallyGossip(state) do
    Process.sleep(100)
    randomNodeNotConverged = Enum.random(GenServer.call(PushTheGossip.Convergence,{:getState}))
    if randomNodeNotConverged != [] || randomNodeNotConverged != nil do
        GenServer.cast(Map.get(state,randomNodeNotConverged), {:transrumor, "Infection!"})
        #IO.puts("randomly send #{inspect Map.get(state,randomNodeNotConverged)} => #{inspect randomNodeNotConverged} => #{inspect Process.alive?Map.get(state,randomNodeNotConverged)}")
        periodicallyGossip(state)
      else
        nil
    end
  end

  def periodicallyPush(state) do
    Process.sleep(100)
    randomNodeNotConverged = Enum.random(GenServer.call(PushTheGossip.Convergence,{:getState}))
    if randomNodeNotConverged != [] || randomNodeNotConverged != nil do
        GenServer.cast(Map.get(state,randomNodeNotConverged), {:receive,{0,0}})
        periodicallyPush(state)
      else
        nil
    end
  end

  # ======================= Gossip Start ================================#
  #topology are gossip_full, gossip_line
  def gossip(numNodes,topology) do
    cond do
      Enum.member?(["gossip_full","gossip_line","gossip_random_2D"],topology) ->
        nodeList = AdjacencyHelper.getNodeList(topology,numNodes)
        for i <- 1..numNodes do
        _=  GenServer.call(KV.Registry, {:create_gossip,
          %{name: Enum.at(nodeList,i-1),numNodes: numNodes,topology: topology, nodeList: nodeList,numbering: i}})
        end
        state = GenServer.call(KV.Registry, {:getState})
        if state != %{} do
          {name, random_pid} = Enum.random(state)
          GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes,nodeList] })
          GenServer.cast(random_pid, {:transrumor, "Infection!"})
          periodicallyGossip(state)
        end
      topology == "gossip_3D" ->
        gossip3D(numNodes)
      Enum.member?(["gossip_honeycomb","gossip_random_honeycomb"],topology) ->
        gossipHoneycombAndRandomHoneyComb(numNodes,topology)
    end
  end

  # ======================= Gossip End ================================#



  # ======================= Gossip 3D Start ================================#

  def gossip3D(numNodes) do
    rowcnt = round(:math.pow(numNodes, 1 / 3))
    rowcnt_square = rowcnt * rowcnt
    perfect_cube = round(:math.pow(rowcnt,3))
    if numNodes != perfect_cube do
     IO.puts("perfect_cube #{perfect_cube}!")
    end
    list_of_neighbours = AdjacencyHelper.getNodeListFor3D(numNodes, rowcnt, rowcnt_square)
    for i <- 1..perfect_cube do
      _=GenServer.call(
        KV.Registry,{:create_gossip,
        %{name: i,numNodes: numNodes,topology: "gossip_3D", nodeList: list_of_neighbours,numbering: nil}})
    end
    state = GenServer.call(KV.Registry, {:getState})
    nodeList = Enum.map(state, fn {k,v} -> k end)
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), perfect_cube,nodeList] })
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      periodicallyGossip(state)
    end
  end

  # ======================= Gossip 3D End ================================#

  # ======================= Gossip Honeycomb/Random Honeycomb Start ================================#

  def gossipHoneycombAndRandomHoneyComb(numNodes,topology) do
    map_of_neighbours = AdjacencyHelper.getNodeList(topology,numNodes)
    nodeList = Enum.map(map_of_neighbours, fn {k, v} -> k end)
    for i <- 1..numNodes do
      _=GenServer.call(
        KV.Registry,
        {:create_gossip,
          %{name: [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)],
          numNodes: numNodes,topology: topology, nodeList: map_of_neighbours,numbering: i}})
    end
    state = GenServer.call(KV.Registry, {:getState})
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), map_size(map_of_neighbours),nodeList] })
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      periodicallyGossip(state)
    end
  end

  # ======================= Gossip Honeycomb End ================================#


end
