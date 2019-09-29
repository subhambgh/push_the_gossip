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

  # def gossip(my_name) do
  #   {:ok, my_neighbours} = GenServer.call(KV.Registry, {:getAdjList, my_name})
  #   if my_neighbours != [] && my_neighbours != nil do
  #     random_neighbour = Enum.random(my_neighbours)
  #     IO.puts("sending to #{random_neighbour} from #{my_name}")
  #     {:ok, random_neighbour_pid} = GenServer.call(KV.Registry, {:lookup, random_neighbour})
  #     if random_neighbour_pid ==nil do
  #       #when the random neighbour selected is dead in b/w the function calls
  #       gossip(my_name)
  #     end
  #     GenServer.cast(random_neighbour_pid, {:transrumor, "Infected!"})
  #   else
  #     #remove empty list, %{...,10 => []} - remove 10 here
  #     GenServer.call(KV.Registry, {:updateAdjList,my_name})
  #     #no neighbours so converge the actor
  #     Process.exit(self(), :noNeighbours)
  #   end
  #   gossip(my_name)
  # end

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
      GenServer.cast(PushTheGossip.Convergence, {:i_heard_it, name})
      {:noreply, {count + 1, name}}
    else
      if count < 100 do
        #IO.inspect(count)
        {:noreply, {count + 1, name}}
      else
        #update this registry is dead
        GenServer.call(KV.Registry, {:updateAdjList,name})
        #Process.exit(self(), :kill)
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
