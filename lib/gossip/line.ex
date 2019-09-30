defmodule KV.GossipLine do
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
    case GenServer.call(KV.Registry, {:getRandomNeighPidFromAdjList, my_name}) do
      nil ->
        GenServer.call(KV.Registry, {:updateAdjList,my_name})
        #Process.exit(self(), :kill)
      [random_neighbour, random_neighbour_pid] ->
        #IO.inspect({my_name,random_neighbour})
        GenServer.cast(random_neighbour_pid, {:transrumor, "Infected!"})
    end

    gossip(my_name)
  end

  # this is the receive
  @impl true
  def handle_cast({:transrumor, rumor}, {count, name}) do
    if count == 0 do
      # infected _ now infect others
      Task.async(fn -> gossip(name) end)
      nodeList = GenServer.call(PushTheGossip.Convergence, {:i_heard_it_remove_me,name})
      IO.inspect(nodeList)
      {:noreply, {count + 1, name}}
    else
      if count < 100 do
        #IO.inspect(count)
        {:noreply, {count + 1, name}}
      else
        # update this registry is dead
        GenServer.call(KV.Registry, {:updateAdjList, name})
        # ---------------------imp-------------------
        # most probably:-killing itself here causes the task created above to exit where
        # it shuts down all the other actors as well
        # ---------------------imp-------------------
        # Process.exit(self(), :kill)
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
