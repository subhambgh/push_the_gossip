defmodule PushTheGossip.Main do

  def main(args \\ []) do
    {numNodes,""} = Integer.parse(Enum.at(args,0))
    topology = Enum.at(args,1)
    algorithm = Enum.at(args,2)
    {failNodes,""}=
      if Enum.at(args,3)== nil do
        {0,""}
      else
        Integer.parse(Enum.at(args,3))
      end
    {maxWaitTime,""}=
      if Enum.at(args,4)== nil do
        {9999999,""}
      else
        Integer.parse(Enum.at(args,4))
      end
    start(numNodes, topology,algorithm,failNodes,maxWaitTime)
  end

  def start(numNodes,topology,algorithm,failNodes,maxWaitTime) do

    case algorithm do
      "gossip" ->
        gossip(numNodes,topology,failNodes,maxWaitTime)
      "push-sum"->
        pushSum(numNodes,topology,failNodes,maxWaitTime)
    end
  end

  def infinite(maxWaitTime,failNodes) do
    timer(maxWaitTime,failNodes)
  end

  def timer(maxWaitTime,failNodes) do
    {time_start,numNodes,nodesConverged,_} = GenServer.call(PushTheGossip.Convergence,{:getState})
    #IO.puts "#{ (System.system_time(:millisecond) - time_start)}  #{maxWaitTime}  #{(System.system_time(:millisecond) - time_start) >= maxWaitTime}"
    if (System.system_time(:millisecond) - time_start) >= maxWaitTime && !(numNodes==nodesConverged) do
      IO.puts("Remaning Nodes #{numNodes-nodesConverged} & Convergence % =  #{(nodesConverged/numNodes)*100}")
      System.halt(1)
    else
      timer(maxWaitTime,failNodes)
    end
  end

  # ======================= Gossip Start ================================#
  #topology are gossip_full, gossip_line
  def gossip(numNodes,topology,failNodes,maxWaitTime) do
    cond do
      Enum.member?(["full","line"],topology) ->
        nodeList = AdjacencyHelper.getNodeList(topology,numNodes)
        #IO.inspect nodeList
        for i <- 1..numNodes do
          {ok,pid} = Gossip.start_link(
            %{name: Enum.at(nodeList,i-1),numNodes: numNodes,topology: topology,nodeList: nodeList})
          ref = Process.monitor(pid)
        end
        GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes]})
        GenServer.cast(Gossip.whereis(round(numNodes/2)), {:receive, "Infection!"})
        infinite(maxWaitTime,failNodes)
      topology == "rand2D" ->
        gossipRand2D(numNodes)
        infinite(maxWaitTime,failNodes)
      topology == "3Dtorus" ->
        gossip3D(numNodes)
        infinite(maxWaitTime,failNodes)
      Enum.member?(["honeycomb","randhoneycomb"],topology) ->
        gossipHoneycombAndRandomHoneyComb(numNodes,topology)
        infinite(maxWaitTime,failNodes)
    end
  end

  # ======================= Gossip End ================================#

  # ===================== Push Sum Start ==============================#

  def pushSum(numNodes,topology,failNodes,maxWaitTime) do
    cond do
      Enum.member?(["full","line"],topology) ->
        nodeList = AdjacencyHelper.getNodeList(topology,numNodes)
      for i <- 1..numNodes do
        {ok,pid} = PushSum.start_link(
          %{name: Enum.at(nodeList,i-1),s: i,w: 1,numNodes: numNodes,topology: topology,nodeList: nodeList})
        ref = Process.monitor(pid)
      end
      # initialize
      GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
      GenServer.cast(PushSum.whereis(round(numNodes/2)), {:receive, {0, 0}})
      infinite(maxWaitTime,failNodes)
    topology == "rand2D" ->
      pushSumRand2D(numNodes)
      infinite(maxWaitTime,failNodes)
    topology == "3Dtorus" ->
      pushSum3D(numNodes)
      infinite(maxWaitTime,failNodes)
    Enum.member?(["honeycomb","randhoneycomb"],topology) ->
      pushSumHoneycombAndRandomHoneyComb(numNodes,topology)
      infinite(maxWaitTime,failNodes)
    end
  end

  # ===================== Push Sum End ==============================#

  #################### Random 2D, 3D and honeycomb implementations #####################
  # ======================= Gossip Random 2D Start ================================#
  def gossipRand2D(numNodes) do
    nodeList = AdjacencyHelper.getNodeList("rand2D",numNodes)
    map_of_neighbours = AdjacencyHelper.generate_neighbours_for_random2D(nodeList)
    for i <- 1..numNodes do
      {ok,pid} = Gossip.start_link(
        %{name: Enum.at(nodeList,i-1),numNodes: numNodes,topology: "rand2D",nodeList: nodeList,mapOfNeighbours: map_of_neighbours,numbering: i})
      ref = Process.monitor(pid)
    end
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes]})
    GenServer.cast(Gossip.whereis(Enum.at(nodeList,round(numNodes/2)-1)), {:receive, "Infection!"})
  end

  # ======================= Gossip Random 2D End ================================#
  # ======================= Gossip 3D Start ================================#

  def gossip3D(numNodes) do
    rowcnt = round(:math.pow(numNodes, 1 / 3))
    rowcnt_square = rowcnt * rowcnt
    perfect_cube = round(:math.pow(rowcnt,3))
    if numNodes != perfect_cube do
     #IO.puts("perfect_cube #{perfect_cube}!")
    end
    list_of_neighbours = AdjacencyHelper.getNodeListFor3D(numNodes, rowcnt, rowcnt_square)
    for i <- 1..perfect_cube do
      {ok,pid} = Gossip.start_link(
        %{name: i,numNodes: numNodes,topology: "3Dtorus", nodeList: list_of_neighbours})
      ref = Process.monitor(pid)
    end
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), perfect_cube] })
    GenServer.cast(Gossip.whereis(round(numNodes/2)), {:receive, "Infection!"})
  end

  # ======================= Gossip 3D End ================================#

  # ======================= Gossip Honeycomb/Random Honeycomb Start ================================#

  def gossipHoneycombAndRandomHoneyComb(numNodes,topology) do
    map_of_neighbours = AdjacencyHelper.getNodeList(topology,numNodes)
    nodeList = Enum.map(map_of_neighbours, fn {k, v} -> k end)
    numNodes = map_size(map_of_neighbours)
    for i <- 1..numNodes do
      {ok,pid} = Gossip.start_link(
        %{name: [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)],
        numNodes: numNodes,topology: topology, nodeList: nodeList,mapOfNeighbours: map_of_neighbours,numbering: i})
      ref = Process.monitor(pid)
    end
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
    GenServer.cast(Gossip.whereis([Enum.at(Enum.at(nodeList, round(numNodes/2) - 1), 0), Enum.at(Enum.at(nodeList, round(numNodes/2) - 1), 1)]), {:receive, "Infection!"})
  end

  # ======================= Gossip Honeycomb End ================================#
  # ======================= Push Sum Random 2D Start ================================#
  def pushSumRand2D(numNodes) do
    nodeList = AdjacencyHelper.getNodeList("rand2D",numNodes)
    map_of_neighbours = AdjacencyHelper.generate_neighbours_for_random2D(nodeList)
    for i <- 1..numNodes do
      {ok,pid} = PushSum.start_link(
        %{name: Enum.at(nodeList,i-1),s: i,w: 1,numNodes: numNodes,topology: "rand2D",nodeList: nodeList,mapOfNeighbours: map_of_neighbours,numbering: i})
      ref = Process.monitor(pid)
    end
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes]})
    GenServer.cast(PushSum.whereis(Enum.at(nodeList,round(numNodes/2)-1)), {:receive, {0, 0}})
  end

  # ======================= Push Sum Random 2D End ================================#
  # ======================= Push Sum 3D Start ================================#

  def pushSum3D(numNodes) do
    rowcnt = round(:math.pow(numNodes, 1 / 3))
    rowcnt_square = rowcnt * rowcnt
    perfect_cube = round(:math.pow(rowcnt,3))
    if numNodes != perfect_cube do
     #IO.puts("perfect_cube #{perfect_cube}!")
    end
    list_of_neighbours = AdjacencyHelper.getNodeListFor3D(numNodes, rowcnt, rowcnt_square)
    for i <- 1..perfect_cube do
      {ok,pid} = PushSum.start_link(
        %{name: i,s: i,w: 1,numNodes: numNodes,topology: "3Dtorus", nodeList: list_of_neighbours})
      ref = Process.monitor(pid)
    end
    # initialize
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
    GenServer.cast(PushSum.whereis(round(numNodes/2)), {:receive, {0, 0}})
  end

  # ======================= Push Sum 3D End ================================#

  # ======================= Push Sum Honeycomb Start ================================#

  def pushSumHoneycombAndRandomHoneyComb(numNodes,topology) do
    map_of_neighbours = AdjacencyHelper.getNodeList(topology,numNodes)
    nodeList = Enum.map(map_of_neighbours, fn {k, v} -> k end)
    numNodes = map_size(map_of_neighbours)
    for i <- 1..numNodes do
      {ok,pid} = PushSum.start_link(
        %{name: [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)],
        s: i,w: 1,
        numNodes: numNodes,topology: topology, nodeList: nodeList,mapOfNeighbours: map_of_neighbours,numbering: i})
      ref = Process.monitor(pid)
    end
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
    GenServer.cast(PushSum.whereis([Enum.at(Enum.at(nodeList, round(numNodes/2) - 1), 0), Enum.at(Enum.at(nodeList, round(numNodes/2) - 1), 1)]), {:receive, {0, 0}})
  end

  # ======================= Push Sum Honeycomb End ================================#

end
