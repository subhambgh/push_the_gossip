defmodule KV.GossipRandom2D do
  use GenServer

  def start_link([name]) do
    GenServer.start_link(__MODULE__, name)
  end

  @impl true
  def init(name) do
    # Task.async(fn -> gossip() end)
    # {:ok, count, name}
    {:ok, {0, name}}
  end

  def gossip(my_name) do
    # IO.puts("Ok, #{my_name} infected...")
    {:ok, my_neighbours} = GenServer.call(KV.Registry, {:getAdjList, my_name})
    # IO.inspect(my_neighbours)
    state = GenServer.call(KV.Registry, {:getState})

    random_neighbour = Enum.random(my_neighbours)

    {:ok, random_neighbour_pid} = GenServer.call(KV.Registry, {:lookup, random_neighbour})

    # IO.inspect(random_neighbour_pid)

    if random_neighbour_pid != nil do
      IO.puts("#{my_name} sending to #{random_neighbour}")
      GenServer.cast(random_neighbour_pid, {:transrumor, "Infected!"})
    end

    gossip(my_name)
  end

  # this is the receive
  @impl true
  def handle_cast({:transrumor, rumor}, {count, name}) do
    # IO.puts("Message rec..")
    IO.inspect(count)

    if count == 0 do
      # infected _ now infect others
      Task.async(fn -> gossip(name) end)
      {:noreply, {count + 1, name}}
    else
      if count < 10 do
        {:noreply, {count + 1, name}}
      else
        # send(self(), :kill_me_pls)
        Process.exit(self(), :kill)
        {:noreply, {count + 1, name}}
      end
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
