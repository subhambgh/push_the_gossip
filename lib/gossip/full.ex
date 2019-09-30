defmodule KV.GossipFull do
  use GenServer

  def start_link([name]) do
    GenServer.start_link(__MODULE__,name)
  end

  @impl true
  def init(name) do
    count=0
    {:ok, {count, name}}
  end

  def gossip(name) do
    state = GenServer.call(KV.Registry, {:getState})
    if state !=nil && state != %{} && Map.has_key?(state, name) do
      {_, neighbour_pid} = Enum.random(state)
      if neighbour_pid != self() do
        GenServer.cast(neighbour_pid, {:transrumor, "rumor"})
      end
    end
    gossip(name)
  end

  # this is the receive
  @impl true
  def handle_cast({:transrumor, rumor}, {count,name}) do
    if count == 0 do
      # infected _ now infect others
      Task.async(fn -> gossip(name) end)
      GenServer.call(PushTheGossip.Convergence, {:i_heard_it_remove_me,name})
      {:noreply, {count + 1,name}}
    else
      if count < 10 do
        {:noreply, {count + 1,name}}
      else
        #IO.inspect(count)
        GenServer.call(KV.Registry, {:updateMap,name})
        #Process.exit(self(), :count10)
        {:noreply, {count + 1,name}}
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
