defmodule KV.GossipFull do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, _opts)
  end

  @impl true
  def init(:ok) do
    # Task.async(fn -> gossip() end)
    # {:ok, count}
    {:ok, 0}
  end

  def gossip() do
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {_, neighbour_pid} = Enum.random(state)

      if neighbour_pid != self() do
        GenServer.cast(neighbour_pid, {:transrumor, "rumor"})
      end
    end

    gossip()
  end

  # this is the receive
  @impl true
  def handle_cast({:transrumor, rumor}, count) do
    IO.inspect(count)

    if count == 0 do
      # infected _ now infect others
      Task.async(fn -> gossip() end)
      {:noreply, count + 1}
    else
      if count < 10 do
        {:noreply, count + 1}
      else
        # send(self(), :kill_me_pls)
        Process.exit(self(), :kill)
        {:noreply, count + 1}
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
