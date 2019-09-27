defmodule KV.Main do
  # ======================= Gossip Full Start ================================#
  def gossip_full(numNodes) do
    for i <- 1..numNodes do
      GenServer.cast(KV.Registry, {:create_gossip_full, i})
    end

    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {name, random_pid} = Enum.random(state)
      IO.puts("Let's start with #{name} #1")
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      # run()
    end
  end

  # ======================= Gossip Full End ================================#

  # ======================= Gossip Line Start ================================#

  def gossip_line(numNodes) do
    for i <- 1..numNodes do
      GenServer.cast(KV.Registry, {:create_gossip_line, [i, numNodes]})
    end
    # initialize
    state = GenServer.call(KV.Registry, {:getState})
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
    end
  end
  # ======================= Gossip Line End ================================#

  # ======================= Gossip Random 2D Start ================================#

  def gossip_Random_2D(numNodes) do
    # IO.puts("really up here #{numNodes}")

    # START HERE

    nodeList = KV.Registry.generate_random_2D(numNodes, []) #pass empty list first
    IO.puts"nodeList"
    IO.inspect(nodeList)

    map_of_neighbours = KV.Registry.generate_neighbours_for_random2D(numNodes, nodeList)
    IO.puts "map_of_neighbours"
    IO.inspect (map_of_neighbours)

    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(
        KV.Registry,
        {:create_gossip_random_2D, [[Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)], numNodes, map_of_neighbours[[Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)]]]}
      )
    end

    # IO.puts("Done creating")

    # initialize
    state = GenServer.call(KV.Registry, {:getState})
    IO.puts "state"
    IO.inspect(state)

    if state != %{} do
      {name, random_pid} = Enum.random(state)
      IO.puts("Let's start with")
      IO.inspect name
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      # run()
    end
  end

  # ======================= Gossip Random 2D End ================================#


  # ======================= Gossip 3D Start ================================#

  def gossip_3D(numNodes) do
    rowcnt = round(:math.pow(numNodes, 1 / 3))
    rowcnt_square = rowcnt * rowcnt
    list_of_neighbours = KV.Registry.generate3d(numNodes, rowcnt, rowcnt_square)
    IO.inspect(list_of_neighbours)
    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(
        KV.Registry,
        {:create_gossip_3D, [i, numNodes, Enum.at(list_of_neighbours, i - 1)]}
      )
    end
    state = GenServer.call(KV.Registry, {:getState})
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
    end
  end

  # ======================= Gossip 3D End ================================#

  # ======================= Gossip Honeycomb Start ================================#

  def gossip_honeycomb(numNodes) do
    # IO.puts("really up here #{numNodes}")

    map_of_neighbours = KV.Registry.outer_loop(0,numNodes,%{})
    IO.puts "map_of_neighbours"
    IO.inspect (map_of_neighbours)

    nodeList = Enum.map(map_of_neighbours, fn {k,v} -> k end)

    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(
        KV.Registry,
        {:create_gossip_honeycomb, [[Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)], numNodes, map_of_neighbours[[Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)]]]}
      )
    end

    # Enum.each(map_of_neighbours, fn {k, v} ->

    #   Enum.each(v, fn [a,b] ->
    #     GenServer.cast(
    #       KV.Registry,
    #       {:create_gossip_random_2D, [a, b, numNodes, map_of_neighbours[a, b]]}
    #     )


    #   end)

    # end)

    IO.puts("Done creating")

    state = GenServer.call(KV.Registry, {:getState})
    IO.puts "state"
    IO.inspect(state)

    if state != %{} do
      {name, random_pid} = Enum.random(state)
      IO.puts("Let's start with")
      IO.inspect name
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      # run()
    end
  end

  # ======================= Gossip Honeycomb End ================================#

  # ======================= Gossip Ranom Honeycomb Start ================================#

  def gossip_random_honeycomb(numNodes) do
    # IO.puts("really up here #{numNodes}")

    map = KV.Registry.outer_loop(0,numNodes,%{})

    map_of_neighbours = KV.Registry.random_honeycomb(map)
    IO.puts "map"
    IO.inspect (map_of_neighbours)



    nodeList = Enum.map(map_of_neighbours, fn {k,v} -> k end)



    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(
        KV.Registry,
        {:create_gossip_honeycomb, [[Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)], numNodes, map_of_neighbours[[Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)]]]}
      )
    end

    # Enum.each(map_of_neighbours, fn {k, v} ->

    #   Enum.each(v, fn [a,b] ->
    #     GenServer.cast(
    #       KV.Registry,
    #       {:create_gossip_random_2D, [a, b, numNodes, map_of_neighbours[a, b]]}
    #     )


    #   end)

    # end)

    IO.puts("Done creating")

    state = GenServer.call(KV.Registry, {:getState})
    IO.puts "state"
    IO.inspect(state)

    if state != %{} do
      {name, random_pid} = Enum.random(state)
      IO.puts("Let's start with")
      IO.inspect name
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      # run()
    end
  end

  # ======================= Gossip Random Honeycomb End ================================#


  # ===================== Push Sum Full Start ==============================#

  def push_sum_full(numNodes) do
    for i <- 1..numNodes do
      GenServer.cast(KV.Registry, {:create_push_full, i})
    end

    # initialize
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {_, random_pid} = Enum.random(state)
      GenServer.cast(random_pid, {:receive, {0, 0}})
    end
  end

  # ===================== Push Sum Full End ==============================#

  # ===================== Push Sum Line Start ==============================#

  def push_sum_line(numNodes) do
    # IO.puts("really up here #{numNodes}")
    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(KV.Registry, {:create_push_line, [i, numNodes]})
    end

    # initialize
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {name, random_pid} = Enum.random(state)
      IO.puts("Let's start with #{name}")
      GenServer.cast(random_pid, {:receive, {0, 0}})
      # run()
    end
  end

  # ===================== Push Sum Line End ==============================#

  # ======================= Push Sum Random 2D Start ================================#

  def push_sum_Random_2D(numNodes) do
    # IO.puts("really up here #{numNodes}")

    # START here

    nodeList = KV.Registry.generate_random_2D(numNodes, []) #pass empty list first
    IO.puts"nodeList"
    IO.inspect(nodeList)

    map_of_neighbours = KV.Registry.generate_neighbours_for_random2D(numNodes, nodeList)
    IO.puts "map_of_neighbours"
    IO.inspect (map_of_neighbours)

    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(
        KV.Registry,
        {:create_push_random_2D, [[Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)], i, numNodes, map_of_neighbours[[Enum.at(Enum.at(nodeList,i-1),0), Enum.at(Enum.at(nodeList,i-1),1)]]]}
      )
    end

    # IO.puts("Done creating")

    # initialize
    state = GenServer.call(KV.Registry, {:getState})
    IO.puts "state"
    IO.inspect(state)

    if state != %{} do
      {name, random_pid} = Enum.random(state)
      IO.puts("Let's start with")
      IO.inspect name
      GenServer.cast(random_pid, {:receive, {0, 0}})
      # run()
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
      # run()
    end
  end

  # ======================= Push Sum 3D End ================================#
end
