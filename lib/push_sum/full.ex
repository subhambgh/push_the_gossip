  defmodule KV.Bucket2 do
  use GenServer

  def start_link([s, w]) do
    GenServer.start_link(__MODULE__, [s, w])
  end

  @impl true
  def init([s, w]) do
    name = s
    {:ok, {s, w, 0, name}}
  end

  def handle_cast({:send, {received_s, received_w}}, {s, w, count, my_name}) do
    # IO.puts("#{inspect(self())} #{received_s} #{received_w}")
    state = GenServer.call(KV.Registry, {:getState})
    if state != %{} do
      {_, neighbour_pid} = Enum.random(state)
      if neighbour_pid != self() and neighbour_pid != nil do
        GenServer.cast(neighbour_pid, {:receive, {received_s, received_s}})
      else
        GenServer.cast(self(), {:send, {received_s, received_w}})
      end
    else
      GenServer.cast(self(), {:send, {received_s, received_w}})
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
    IO.puts("#{inspect my_name} #{change} #{count}")
    if count >= 3 do
      GenServer.call(KV.Registry, {:updateMap,my_name})
      new_list_of_nodes = GenServer.call(PushTheGossip.Convergence,{:i_heard_it_remove_me, my_name })
      if new_list_of_nodes != [] do
        GenServer.cast(self(), {:send, {s, w}})
      end
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
