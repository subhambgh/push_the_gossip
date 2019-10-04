defmodule PushTheGossip.Main do

  def main(args \\ []) do
    {numNodes,""} = Integer.parse(Enum.at(args,0))
    topology = Enum.at(args,1)
    algorithm = Enum.at(args,2)
    {noOfNodesToFail,""}=
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
    start(numNodes, topology,algorithm,noOfNodesToFail,maxWaitTime)
  end

  def start(numNodes,topology,algorithm,noOfNodesToFail,maxWaitTime) do
    case algorithm do
      "gossip" ->
        gossip(numNodes,topology,noOfNodesToFail,maxWaitTime)
      "push-sum"->
        pushSum(numNodes,topology,noOfNodesToFail,maxWaitTime)
    end
  end

  def infiniteI(numNodes,maxWaitTime,noOfNodesToFail) do
    timerT(numNodes,maxWaitTime,noOfNodesToFail)
  end

   def timerT(orignalNumNodes,maxWaitTime,noOfNodesToFail) do
      state = GenServer.call(PushTheGossip.Convergence,{:getState},:infinity)
      {time_start,numNodes,nodesConverged,_} = state #numNodes here is numNodes - nodesToFail
      if (System.system_time(:millisecond) - time_start) >= maxWaitTime && !(numNodes==nodesConverged) do
        IO.puts("Nodes failed #{noOfNodesToFail} & Convergence =  #{round((nodesConverged/orignalNumNodes)*100)} %")
        System.halt(1)
      else
        timerT(orignalNumNodes,maxWaitTime,noOfNodesToFail)
      end
    end

    def nodesToFail(pidList,noOfNodesToFail) do
      Enum.map(1..noOfNodesToFail, fn _i ->
        nodeToFailPid = Enum.random(pidList)
        _=GenServer.call(nodeToFailPid,{:unregisterMe})
        nodeToFailPid
      end)
    end

  # ======================= Gossip Start ================================#
  #topology are gossip_full, gossip_line
  def gossip(numNodes,topology,noOfNodesToFail,maxWaitTime) do
    cond do
      Enum.member?(["full","line"],topology) ->
        nodeList = AdjacencyHelper.getNodeList(topology,numNodes)
        #IO.inspect nodeList
        pidList =
          for i <- 1..numNodes do
          {_,pid} = Gossip.start_link(
            %{name: i,numNodes: numNodes,topology: topology,nodeList: nodeList})
          _ref = Process.monitor(pid)
          pid
        end
        IO.puts "Nodes created"
        pidList = pidList -- nodesToFail(pidList,noOfNodesToFail)
        IO.puts "Starting Algorithm.."
        GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
        GenServer.cast(Enum.random(pidList), {:receive, "Infection!"})
        infiniteI(numNodes,maxWaitTime,noOfNodesToFail)
      topology == "rand2D" ->
        gossipRand2D(numNodes,noOfNodesToFail)
        infiniteI(numNodes,maxWaitTime,noOfNodesToFail)
      topology == "3Dtorus" ->
        gossip3D(numNodes,noOfNodesToFail)
        infiniteI(numNodes,maxWaitTime,noOfNodesToFail)
      Enum.member?(["honeycomb","randhoneycomb"],topology) ->
        gossipHoneycombAndRandomHoneyComb(numNodes,topology,noOfNodesToFail)
        infiniteI(numNodes,maxWaitTime,noOfNodesToFail)
    end
  end

  # ======================= Gossip End ================================#

  # ===================== Push Sum Start ==============================#

  def pushSum(numNodes,topology,noOfNodesToFail,maxWaitTime) do
    cond do
      Enum.member?(["full","line"],topology) ->
        nodeList = AdjacencyHelper.getNodeList(topology,numNodes)
        pidList =
      for i <- 1..numNodes do
        {_ok,pid} = PushSum.start_link(
          %{name: i,s: i,w: 1,numNodes: numNodes,topology: topology,nodeList: nodeList})
        _ref = Process.monitor(pid)
        pid
      end
      IO.puts "Nodes created"
      pidList = pidList -- nodesToFail(pidList,noOfNodesToFail)
      IO.puts "Starting Algorithm.."
      GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
      GenServer.cast(Enum.random(pidList), {:receive, {0, 0}})
      infiniteI(numNodes,maxWaitTime,noOfNodesToFail)
    topology == "rand2D" ->
      pushSumRand2D(numNodes,noOfNodesToFail)
      infiniteI(numNodes,maxWaitTime,noOfNodesToFail)
    topology == "3Dtorus" ->
      pushSum3D(numNodes,noOfNodesToFail)
      infiniteI(numNodes,maxWaitTime,noOfNodesToFail)
    Enum.member?(["honeycomb","randhoneycomb"],topology) ->
      pushSumHoneycombAndRandomHoneyComb(numNodes,topology,noOfNodesToFail)
      infiniteI(numNodes,maxWaitTime,noOfNodesToFail)
    end
  end

  # ===================== Push Sum End ==============================#

  #################### Random 2D, 3D and honeycomb implementations #####################
  # ======================= Gossip Random 2D Start ================================#
  def gossipRand2D(numNodes,noOfNodesToFail) do
    nodeList = AdjacencyHelper.getNodeList("rand2D",numNodes)
    map_of_neighbours = AdjacencyHelper.generate_neighbours_for_random2D(nodeList)
    pidList =
      for i <- 1..numNodes do
      {_ok,pid} = Gossip.start_link(
        %{name: Enum.at(nodeList,i-1),numNodes: numNodes,topology: "rand2D",nodeList: nodeList,mapOfNeighbours: map_of_neighbours,numbering: i})
      _ref = Process.monitor(pid)
      pid
    end
    IO.puts "Nodes created"
    pidList = pidList -- nodesToFail(pidList,noOfNodesToFail)
    IO.puts "Starting Algorithm.."
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
    GenServer.cast(Enum.random(pidList), {:receive, "Infection!"})
  end

  # ======================= Gossip Random 2D End ================================#
  # ======================= Gossip 3D Start ================================#

  def gossip3D(numNodes,noOfNodesToFail) do
    rowcnt = round(:math.pow(numNodes, 1 / 3))
    rowcnt_square = rowcnt * rowcnt
    perfect_cube = round(:math.pow(rowcnt,3))
    # if numNodes != perfect_cube do
    #  #IO.puts("perfect_cube #{perfect_cube}!")
    # end
    list_of_neighbours = AdjacencyHelper.getNodeListFor3D(numNodes, rowcnt, rowcnt_square)
    pidList =
    for i <- 1..perfect_cube do
      {_ok,pid} = Gossip.start_link(
        %{name: i,numNodes: perfect_cube,topology: "3Dtorus", nodeList: list_of_neighbours})
      _ref = Process.monitor(pid)
      pid
    end
    IO.puts "Nodes created"
    pidList = pidList -- nodesToFail(pidList,noOfNodesToFail)
    IO.puts "Starting Algorithm.."
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), perfect_cube] })
    GenServer.cast(Enum.random(pidList), {:receive, "Infection!"})
  end

  # ======================= Gossip 3D End ================================#

  # ======================= Gossip Honeycomb/Random Honeycomb Start ================================#

  def gossipHoneycombAndRandomHoneyComb(numNodes,topology,noOfNodesToFail) do
    map_of_neighbours = AdjacencyHelper.getNodeList(topology,numNodes)
    nodeList = Enum.map(map_of_neighbours, fn {k, _v} -> k end)
    numNodes = map_size(map_of_neighbours)
    pidList =
    for i <- 1..numNodes do
      {_ok,pid} = Gossip.start_link(
        %{name: [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)],
        numNodes: numNodes,topology: topology, nodeList: nodeList,mapOfNeighbours: map_of_neighbours,numbering: i})
      _ref = Process.monitor(pid)
      pid
    end
    IO.puts "Nodes created"
    pidList = pidList -- nodesToFail(pidList,noOfNodesToFail)
    IO.puts "Starting Algorithm.."
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
    GenServer.cast(Enum.random(pidList), {:receive, "Infection!"})
  end

  # ======================= Gossip Honeycomb End ================================#
  # ======================= Push Sum Random 2D Start ================================#
  def pushSumRand2D(numNodes,noOfNodesToFail) do
    nodeList = AdjacencyHelper.getNodeList("rand2D",numNodes)
    map_of_neighbours = AdjacencyHelper.generate_neighbours_for_random2D(nodeList)
    pidList =
    for i <- 1..numNodes do
      {_ok,pid} = PushSum.start_link(
        %{name: Enum.at(nodeList,i-1),s: i,w: 1,numNodes: numNodes,topology: "rand2D",nodeList: nodeList,mapOfNeighbours: map_of_neighbours,numbering: i})
      _ref = Process.monitor(pid)
      pid
    end
    IO.puts "Nodes created"
    pidList = pidList -- nodesToFail(pidList,noOfNodesToFail)
    IO.puts "Starting Algorithm.."
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
    GenServer.cast(Enum.random(pidList), {:receive, {0, 0}})
  end

  # ======================= Push Sum Random 2D End ================================#
  # ======================= Push Sum 3D Start ================================#

  def pushSum3D(numNodes,noOfNodesToFail) do
    rowcnt = round(:math.pow(numNodes, 1 / 3))
    rowcnt_square = rowcnt * rowcnt
    perfect_cube = round(:math.pow(rowcnt,3))
    if numNodes != perfect_cube do
     #IO.puts("perfect_cube #{perfect_cube}!")
    end
    list_of_neighbours = AdjacencyHelper.getNodeListFor3D(numNodes, rowcnt, rowcnt_square)
    pidList =
    for i <- 1..perfect_cube do
      {_ok,pid} = PushSum.start_link(
        %{name: i,s: i,w: 1,numNodes: perfect_cube,topology: "3Dtorus", nodeList: list_of_neighbours})
      _ref = Process.monitor(pid)
      pid
    end
    IO.puts "Nodes created"
    pidList = pidList -- nodesToFail(pidList,noOfNodesToFail)
    IO.puts "Starting Algorithm.."
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), perfect_cube] })
    GenServer.cast(Enum.random(pidList), {:receive, {0, 0}})
  end

  # ======================= Push Sum 3D End ================================#

  # ======================= Push Sum Honeycomb Start ================================#

  def pushSumHoneycombAndRandomHoneyComb(numNodes,topology,noOfNodesToFail) do
    map_of_neighbours = AdjacencyHelper.getNodeList(topology,numNodes)
    nodeList = Enum.map(map_of_neighbours, fn {k, _v} -> k end)
    numNodes = map_size(map_of_neighbours)
    pidList =
    for i <- 1..numNodes do
      {_ok,pid} = PushSum.start_link(
        %{name: [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)],
        s: i,w: 1,
        numNodes: numNodes,topology: topology, nodeList: nodeList,mapOfNeighbours: map_of_neighbours,numbering: i})
      _ref = Process.monitor(pid)
      pid
    end
    IO.puts "Nodes created"
    pidList = pidList -- nodesToFail(pidList,noOfNodesToFail)
    IO.puts "Starting Algorithm.."
    GenServer.cast(PushTheGossip.Convergence, {:time_start, [System.system_time(:millisecond), numNodes] })
    GenServer.cast(Enum.random(pidList), {:receive, {0, 0}})
  end

  # ======================= Push Sum Honeycomb End ================================#

end
