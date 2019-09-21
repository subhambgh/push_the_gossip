defmodule KV.Bucket do
  use GenServer

  def start_link(count) do
    GenServer.start_link(__MODULE__, count)
  end

  @impl true
  def init(count) do
    Task.async(fn -> gossip() end)
    {:ok, count}
  end

  def gossip() do
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {_, neighbour_pid} = Enum.random(state)

      if neighbour_pid != nil && neighbour_pid != self() do
        GenServer.cast(neighbour_pid, {:transrumor, "rumor"})
      end
    end

    gossip()
  end

  # this is the receive
  @impl true
  def handle_cast({:transrumor, rumor}, count) do
    IO.inspect(count)

    if(count < 10) do
      {:noreply, count + 1}
    else
      # {:stop, reason, new_state}
      # {:stop, :normal, count}
      Process.exit(self(), :kill)
      {:noreply, "killed"}
    end
  end
end
