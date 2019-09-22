defmodule KV.Main do
  def gossip_full(numNodes) do
    for i <- 1..numNodes do
      GenServer.cast(KV.Registry, {:create_gossip_full, i})
    end
  end

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

  def push_sum_line(numNodes) do
    #IO.puts("really up here #{numNodes}")
    for i <- 1..numNodes do
      #IO.puts("up here #{numNodes}")
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

end
