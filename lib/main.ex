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
    # IO.puts("really up here #{numNodes}")
    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(KV.Registry, {:create_gossip_line, [i, numNodes]})
    end

    IO.puts("Done creating")

    # initialize
    state = GenServer.call(KV.Registry, {:getState})
    IO.inspect(state)
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      IO.puts("Let's start with #{name}")
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      # run()
    end
  end

  # ======================= Gossip Line End ================================#

  # ======================= Gossip 3D Start ================================#

  def gossip_3D(numNodes) do
    # IO.puts("really up here #{numNodes}")

    rowcnt = round(:math.pow(numNodes, 1/3))
    rowcnt_square = rowcnt * rowcnt

    list_of_neighbours = KV.Registry.generate3d(numNodes, rowcnt, rowcnt_square)
    IO.inspect(list_of_neighbours)

    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(KV.Registry, {:create_gossip_3D, [i, numNodes, Enum.at(list_of_neighbours, i-1) ]})
    end

    #IO.puts("Done creating")

    # initialize
    state = GenServer.call(KV.Registry, {:getState})
    IO.inspect(state)
    if state != %{} do
      {name, random_pid} = Enum.random(state)
      IO.puts("Let's start with #{name}")
      GenServer.cast(random_pid, {:transrumor, "Infection!"})
      # run()
    end
  end

  # ======================= Gossip 3D End ================================#


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

  # ======================= Push Sum 3D Start ================================#

  def push_sum_3D(numNodes) do
    # IO.puts("really up here #{numNodes}")

    rowcnt = round(:math.pow(numNodes, 1/3))
    rowcnt_square = rowcnt * rowcnt

    list_of_neighbours = KV.Registry.generate3d(numNodes, rowcnt, rowcnt_square)
    IO.inspect(list_of_neighbours)

    for i <- 1..numNodes do
      # IO.puts("up here #{numNodes}")
      GenServer.cast(KV.Registry, {:create_push_3D, [i, numNodes, Enum.at(list_of_neighbours, i-1) ]})
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
