defmodule KV.PushSumLine do
  use GenServer

  def start_link([s, w]) do
    GenServer.start_link(__MODULE__, [s, w])
  end

  @impl true
  def init([s, w]) do
    # Task.async(fn-> gossip(s,w,1000) end)
    # Task.async(fn-> run() end)
    # 0 for count
    {:ok, {s, w, 0, s}}  #{:ok, s, w, count, node's name (same as s)}
  end

  # def gossip(s,w) do
  def handle_cast({:send, {received_s, received_w}}, {s, w, count, my_name}) do
    # IO.puts("#{inspect(self())} #{received_s} #{received_w}")

    {:ok, my_neighbours} = GenServer.call(KV.Registry, {:getAdjList, my_name})
    # IO.inspect(my_neighbours)
    state = GenServer.call(KV.Registry, {:getState})

    random_neighbour = Enum.random(my_neighbours)

    {:ok, random_neighbour_pid} = GenServer.call(KV.Registry, {:lookup, random_neighbour})

    # IO.inspect(random_neighbour_pid)

    if random_neighbour_pid != nil do
      IO.puts("#{my_name} sending to #{random_neighbour}")
      GenServer.cast(random_neighbour_pid, {:receive, {received_s, received_s}})
    else
      # incase the map is not initialized

      GenServer.cast(self(), {:gossip, {received_s, received_w}})
    end

    {:noreply, {s, w, count, my_name}}
  end

  # this is the receive
  @impl true
  def handle_cast({:receive, {received_s, received_w}}, {s, w, count, my_name}) do
    # IO.puts("#{inspect(self())} #{received_s} #{received_w} #{count}")
    old_ratio = s / w
    s = received_s + s
    w = received_w + w
    new_ratio = s / w
    s = s / 2
    w = w / 2
    change = abs(old_ratio - new_ratio)
    count = if change > :math.pow(10, -10), do: 0, else: count + 1
    IO.puts("#{inspect(self())} #{received_s} #{received_w} #{count}")

    if count >= 3 do
      # V.VampireState.print(V.VampireState)
      Process.exit(self(), :kill)
      {:noreply, {s, w, count, my_name}}
    else
      # gossip(s,w)
      # V.VampireState.push(V.VampireState,self(),{s,w,count})
      GenServer.cast(self(), {:send, {s, w}})
      {:noreply, {s, w, count, my_name}}
    end
  end

  @impl true
  def handle_info({_ref, _}, _state) do
    IO.puts("handle_info")
  end

  @impl true
  def terminate(_, _state) do
    IO.inspect("Look! I'm dead.")
  end
end
