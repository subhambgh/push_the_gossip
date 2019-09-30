defmodule KV.Main do

  def periodicallyGossip(state) do
    Process.sleep(100)
    randomNodeNotConverged = Enum.random(GenServer.call(PushTheGossip.Convergence,{:getState}))
    if randomNodeNotConverged != [] || randomNodeNotConverged != nil do
        GenServer.cast(Map.get(state,randomNodeNotConverged), {:transrumor, "Infection!"})
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

  # ======================= Gossip Full Start ================================#
  def gossip_full(numNodes) do
    for i <- 1..numNodes do
      GenServer.call(KV.Registry, {:create_gossip_full, i})
    end

    nodeList = Enum.map(1..numNodes, fn n -> n end)
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {name, random_pid} = Enum.random(state)
      #IO.puts("Let's start with #{name} #1")
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes,nodeList] })
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      periodicallyGossip(state)
    end
  end

  # ======================= Gossip Full End ================================#

  # ======================= Gossip Line Start ================================#

  def gossip_line(numNodes) do
    for i <- 1..numNodes do
      GenServer.cast(KV.Registry, {:create_gossip_line, [i, numNodes]})
    end

    nodeList = Enum.map(1..numNodes, fn n -> n end)
    # initialize
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {name, random_pid} = Enum.random(state)
        GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes,nodeList] })
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      periodicallyGossip(state)
    end
  end

  # ======================= Gossip Line End ================================#

  # ======================= Gossip Random 2D Start ================================#

  def gossip_random_2D(numNodes) do
    nodeList = KV.Registry.generate_random_2D(numNodes, []) #pass empty list first
    map_of_neighbours = KV.Registry.generate_neighbours_for_random2D(nodeList)
    for i <- 1..numNodes do
      GenServer.cast(
        KV.Registry,
        {:create_gossip_random_2D,
        [
          [Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)],
          map_of_neighbours[[Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)]]
        ]}
      )
    end
    # initialize
    state = GenServer.call(KV.Registry, {:getState})
    adj = GenServer.call(KV.Registry, {:getStateAdj})
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      #IO.puts("Let's start with")
      #IO.inspect name
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes,nodeList] })
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      periodicallyGossip(state)
    end
  end

  # ======================= Gossip Random 2D End ================================#

  # ======================= Gossip 3D Start ================================#

  def gossip_3D(numNodes) do
    rowcnt = round(:math.pow(numNodes, 1 / 3))
    rowcnt_square = rowcnt * rowcnt
    perfect_cube = :math.pow(rowcnt,3)
    if numNodes != perfect_cube do
     IO.puts("perfect_cube #{perfect_cube}!")
    end
    list_of_neighbours = KV.Registry.generate3d(numNodes, rowcnt, rowcnt_square)
    for i <- 1..numNodes-1 do
      GenServer.cast(
        KV.Registry,
        {:create_gossip_3D, [Enum.at(list_of_neighbours, i), numNodes, Enum.at(list_of_neighbours, i - 1)]}
      )
    end
    state = GenServer.call(KV.Registry, {:getState})
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), perfect_cube,list_of_neighbours] })
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      periodicallyGossip(state)
    end
  end

  # ======================= Gossip 3D End ================================#

  # ======================= Gossip Honeycomb Start ================================#

  def gossip_honeycomb(numNodes) do
    map_of_neighbours = KV.Registry.outer_loop(0,numNodes,%{})
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
    state = GenServer.call(KV.Registry, {:getState})
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
    state = GenServer.call(KV.Registry, {:getState})
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
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
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
      GenServer.cast(KV.Registry, {:create_push_line, [i, numNodes]})
    end
    nodeList = Enum.map(1..numNodes, fn n -> n end)
    # initialize
    state = GenServer.call(KV.Registry, {:getState})
    if state != %{} do
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
           [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)],
           i,
           numNodes,
           map_of_neighbours[
             [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)]
           ]
         ]}
      )
    end
    # initialize
    state = GenServer.call(KV.Registry, {:getState})
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      GenServer.cast(PushTheGossip.Convergence, {:time_start_with_list, [System.system_time(:millisecond), numNodes, nodeList] })
      GenServer.cast(random_pid, {:receive, {0, 0}})
      periodicallyPush(state)
    end
  end
  # ======================= Push Sum Random 2D End ================================#

  # ======================= Push Sum 3D Start ================================#

  def push_sum_3D(numNodes) do
    # IO.puts("really up here #{numNodes}")

    rowcnt = round(:math.pow(numNodes, 1 / 3))
    rowcnt_square = rowcnt * rowcnt

    list_of_neighbours = KV.Registry.generate3d(numNodes, rowcnt, rowcnt_square)
    IO.inspect(list_of_neighbours)

    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(
        KV.Registry,
        {:create_push_3D, [i, numNodes, Enum.at(list_of_neighbours, i - 1)]}
      )
    end

    IO.puts("Done creating")

    # initialize
    state = GenServer.call(KV.Registry, {:getState})
    IO.inspect(state)

    if state != %{} do
      {name, random_pid} = Enum.random(state)
      IO.puts("Let's start with #{name}")
      GenServer.cast(random_pid, {:receive, {0, 0}})
      periodicallyPush(state)
    end
  end

  # ======================= Push Sum 3D End ================================#
end
