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

end
