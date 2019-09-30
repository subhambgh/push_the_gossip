defmodule KV.PushSumLine do
  use GenServer

  def start_link([s, w, name]) do
    GenServer.start_link(__MODULE__, [s, w, name])
  end

  @impl true
  def init([s, w, name]) do
    {:ok, {s, w, 0, name}}
  end

  def handle_cast({:send, {received_s, received_w}}, {s, w, count, my_name}) do
    case GenServer.call(KV.Registry, {:getRandomNeighPidFromAdjList, my_name}) do
      nil ->
        GenServer.call(KV.Registry, {:updateAdjList,my_name})
      [random_neighbour, random_neighbour_pid] ->
        GenServer.cast(random_neighbour_pid, {:receive, {received_s, received_w}})
    end
    {:noreply, {s, w, count, my_name}}
  end


  # this is the receive
  @impl true
  def handle_cast({:receive, {received_s, received_w}}, {s, w, count, my_name}) do
    old_ratio = s / w
    s = received_s + s
    w = received_w + w
    new_ratio = s / w
    s = s / 2
    w = w / 2
    change = abs(old_ratio - new_ratio)
    count = if change > :math.pow(10, -10), do: 0, else: count + 1

    if count >= 3 do
      case GenServer.call(KV.Registry, {:getRandomNeighPidFromAdjList, my_name}) do
        nil -> nil
        [random_neighbour, random_neighbour_pid] ->
          GenServer.cast(random_neighbour_pid, {:receive, {received_s, received_w}})
      end
      _ = GenServer.call(KV.Registry, {:updateAdjList,my_name})
      new_list_of_nodes = GenServer.call(PushTheGossip.Convergence,{:i_heard_it_remove_me, my_name })
      {:noreply, {s, w, count, my_name}}
    else
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
