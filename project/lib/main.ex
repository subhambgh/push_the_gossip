defmodule PushTheGossip.Main do

  def main(args \\ []) do
    IO.inspect(args)
    {numNodes,""} = Integer.parse(Enum.at(args,0))
    topology = Enum.at(args,1)
    algorithm = Enum.at(args,2)
    start(numNodes, topology,algorithm)
  end

  def start(numNodes,topology,algorithm) do

    #IO.puts("#{numNodes} #{topology} #{algorithm}")

    case algorithm do
      "gossip" ->
        gossip(numNodes,topology)
        "push-sum"->
          case topology do
            "full" ->push_sum_full(numNodes)
            "line" ->push_sum_line(numNodes)
            "rand2D" ->push_sum_random_2D(numNodes)
            "3Dtorus" ->push_sum_3D(numNodes)
            "honeycomb" ->push_sum_honeycomb(numNodes)
            "randhoneycomb" ->push_sum_random_honeycomb(numNodes)
          end
    end
  end

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
    #IO.inspect(randomNodeNotConverged)
    if randomNodeNotConverged != [] || randomNodeNotConverged != nil do
        #IO.puts("#{inspect( Process.alive?(Map.get(state,randomNodeNotConverged)) )}")
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
      Enum.member?(["full","line","rand2D"],topology) ->
        nodeList = AdjacencyHelper.getNodeList(topology,numNodes)
        for i <- 1..numNodes do
        _=  GenServer.call(KV.Registry, {:create_gossip,
          %{name: Enum.at(nodeList,i-1),numNodes: numNodes,topology: topology, nodeList: nodeList,numbering: i}})
        end
        state = GenServer.call(KV.Registry, {:getState},:infinity)
        if state != %{} do
          {name, random_pid} = Enum.random(state)
          GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes,nodeList] })
          GenServer.cast(random_pid, {:transrumor, "Infection!"})
          periodicallyGossip(state)
        end
      topology == "3Dtorus" ->
        gossip3D(numNodes)
      Enum.member?(["honeycomb","randhoneycomb"],topology) ->
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
        %{name: i,numNodes: numNodes,topology: "3Dtorus", nodeList: list_of_neighbours,numbering: nil}})
    end
    state = GenServer.call(KV.Registry, {:getState},:infinity)
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
    state = GenServer.call(KV.Registry, {:getState},:infinity)
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), map_size(map_of_neighbours),nodeList] })
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      periodicallyGossip(state)
    end
  end

  # ======================= Gossip Honeycomb End ================================#

  # ======================= Gossip Ranom Honeycomb Start ================================#

  def gossip_random_honeycomb(numNodes) do
    map = KV.Registry.outer_loop(0,numNodes,%{})
    map_of_neighbours = KV.Registry.random_honeycomb(map)
    nodeList = Enum.map(map_of_neighbours, fn {k, v} -> k end)
    for i <- 1..numNodes do
      GenServer.cast(
        KV.Registry,
        {:create_gossip_honeycomb,
         [
           [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)],
           numNodes,
           map_of_neighbours[
             [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)]
           ]
         ]}
      )
    end
    state = GenServer.call(KV.Registry, {:getState},:infinity)
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), map_size(map_of_neighbours),nodeList] })
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      periodicallyGossip(state)
    end
  end

  # ======================= Gossip Random Honeycomb End ================================#

  # ===================== Push Sum Full Start ==============================#

  def push_sum_full(numNodes) do
    for i <- 1..numNodes do
      GenServer.cast(KV.Registry, {:create_push_full, i})
    end
    nodeList = Enum.map(1..numNodes, fn n -> n end)
    # initialize
    state = GenServer.call(KV.Registry, {:getState},:infinity)
    IO.inspect(state)

    list_of_pids = Enum.map(state, fn {k,v} -> v end)

    if state != %{} do

      for i <- 1..numNodes do
        new_list_of_pids = List.delete(list_of_pids, Enum.at(list_of_pids, i - 1))
        GenServer.cast(Enum.at(list_of_pids, i - 1), {:update_neighbours, new_list_of_pids})
      end

      {_, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes, nodeList] })
      GenServer.cast(random_pid, {:receive, {0, 0}})
      periodicallyPush(state)
    end
  end

  # ===================== Push Sum Full End ==============================#

  # ===================== Push Sum Line Start ==============================#

  def push_sum_line(numNodes) do
    for i <- 1..numNodes do
      GenServer.cast(KV.Registry, {:create_push_line, [i]})
    end
    nodeList = Enum.map(1..numNodes, fn n -> n end)
    # initialize
    state = GenServer.call(KV.Registry, {:getState},:infinity)
    #list_of_pids = Enum.map(state, fn {k,v} -> v end)

    node_neighbour_list = KV.Registry.make_a_line(numNodes)

    node_neighbour_pid_list = Enum.map(node_neighbour_list, fn neighbours ->
                                Enum.map(neighbours, fn neighbour ->
                                  state[neighbour]
                                end)
                              end)

    #IO.inspect(state)

    #IO.inspect(node_neighbour_list)
    IO.inspect(node_neighbour_pid_list)

    if state != %{} do

      for i <- 1..numNodes do
        #new_list_of_pids = List.delete(list_of_pids, Enum.at(list_of_pids, i - 1))
        GenServer.cast(state[i], {:update_neighbours, Enum.at(node_neighbour_pid_list, i - 1)})
      end

      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes, nodeList] })
      GenServer.cast(random_pid, {:receive, {0, 0}})
      periodicallyPush(state)
    end
  end

  # ===================== Push Sum Line End ==============================#

  # ======================= Push Sum Random 2D Start ================================#

  def push_sum_random_2D(numNodes) do
    nodeList = KV.Registry.generate_random_2D(numNodes, [])
    map_of_neighbours = KV.Registry.generate_neighbours_for_random2D(nodeList)
    for i <- 1..numNodes do
      GenServer.cast(
        KV.Registry,
        {:create_push_random_2D,
         [
           Enum.at(nodeList, i - 1),
           i
         ]}
      )
    end
    # initialize
    state = GenServer.call(KV.Registry, {:getState},:infinity)

    # IO.inspect(map_of_neighbours)
    IO.inspect(state)


    node_neighbour_pid_map = Map.new(Enum.map(map_of_neighbours, fn {k,v} ->
        {k, Enum.map(v, fn node ->

          state[node]

        end)}

      end)
    )

    IO.inspect(node_neighbour_pid_map)

    if state != %{} do


      for i <- 1..numNodes do
        GenServer.cast(state[Enum.at(nodeList, i-1)], {:update_neighbours, node_neighbour_pid_map[Enum.at(nodeList, i-1)]})
      end

      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes, nodeList] })
      GenServer.cast(random_pid, {:receive, {0, 0}})
      periodicallyPush(state)
    end
  end
  # ======================= Push Sum Random 2D End ================================#

  # ======================= Push Sum 3D Start ================================#

  def push_sum_3D(numNodes) do
    rowcnt = round(:math.pow(numNodes, 1 / 3))
    rowcnt_square = rowcnt * rowcnt
    list_of_neighbours = KV.Registry.generate3d(numNodes, rowcnt, rowcnt_square)
    row_cnt_cube = round(:math.pow(rowcnt, 3))
    for i <- 1..row_cnt_cube do
      GenServer.cast(
        KV.Registry,
        {:create_push_full, i}
      )
    end

    IO.inspect(list_of_neighbours)
    # initialize
    state = GenServer.call(KV.Registry, {:getState},:infinity)
    nodeList = Enum.map(state, fn {k,v} -> k end)

    node_neighbour_pid_map =
        Enum.map(list_of_neighbours, fn list_of_a_neighbour ->

          Enum.map( list_of_a_neighbour, fn n->

            state[n]

          end)

        end)

    IO.inspect(node_neighbour_pid_map)


    IO.inspect(state)
    if state != %{} do

      for i <- 1..row_cnt_cube do
        IO.puts("#{inspect state[i]} #{inspect Enum.at(node_neighbour_pid_map, i-1)} ")
        GenServer.cast(state[i], {:update_neighbours, Enum.at(node_neighbour_pid_map, i-1)})
      end

      IO.puts "hogaya"

      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes, nodeList] })
      GenServer.cast(random_pid, {:receive, {0, 0}})
      periodicallyPush(state)
    end
  end

  # ======================= Push Sum 3D End ================================#

  # ======================= Push Sum Honeycomb Start ================================#

  def push_sum_honeycomb(numNodes) do
    map_of_neighbours = KV.Registry.outer_loop(0,numNodes,%{})
    nodeList = Enum.map(map_of_neighbours, fn {k, v} -> k end)
    new_size = length(nodeList)
    for i <- 1..new_size do
      GenServer.cast(
        KV.Registry,
        {:create_push_random_2D, [
                             Enum.at(nodeList, i - 1),
                             i
                          ]}
      )
    end


    state = GenServer.call(KV.Registry, {:getState},:infinity)
    node_neighbour_pid_map = Map.new(Enum.map(map_of_neighbours, fn {k,v} ->
        {k, Enum.map(v, fn node ->

          state[node]

        end)}

      end)
    )

    # initialize

    # IO.inspect(nodeList)
    # IO.inspect(state)
    # IO.inspect(map_of_neighbours)
    # IO.inspect(node_neighbour_pid_map)
    if state != %{} do

      for i <- 1..new_size do
        GenServer.cast(state[Enum.at(nodeList, i-1)], {:update_neighbours, node_neighbour_pid_map[Enum.at(nodeList, i-1)]})
      end


      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes, nodeList] })
      GenServer.cast(random_pid, {:receive, {0, 0}})
      periodicallyPush(state)
    end
  end

  # ======================= Push Sum Honeycomb End ================================#

  # ======================= Push Sum Random Honeycomb Start ================================#

  def push_sum_random_honeycomb(numNodes) do
    map = KV.Registry.outer_loop(0,numNodes,%{})
    #IO.inspect(map)
    map_of_neighbours = KV.Registry.random_honeycomb(map)
    #map_of_neighbours = KV.Registry.random_honeycomb(map)
    nodeList = Enum.map(map_of_neighbours, fn {k, v} -> k end)
    new_size = length(nodeList)
    for i <- 1..new_size do
      GenServer.cast(
        KV.Registry,
        {:create_push_random_2D, [
                             Enum.at(nodeList, i - 1),
                             i
                          ]}
      )
    end
    # initialize
    state = GenServer.call(KV.Registry, {:getState},:infinity)
    node_neighbour_pid_map = Map.new(Enum.map(map_of_neighbours, fn {k,v} ->
        {k, Enum.map(v, fn node ->

          state[node]

        end)}

      end)
    )
    IO.inspect(map_of_neighbours)
    # IO.inspect(state)
    # IO.inspect(nodeList)

    if state != %{} do

      for i <- 1..new_size do
        GenServer.cast(state[Enum.at(nodeList, i-1)], {:update_neighbours, node_neighbour_pid_map[Enum.at(nodeList, i-1)]})
      end


      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes, nodeList] })
      GenServer.cast(random_pid, {:receive, {0, 0}})
      periodicallyPush(state)
    end
  end

end
