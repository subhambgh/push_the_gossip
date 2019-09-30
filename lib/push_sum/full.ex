  defmodule KV.Bucket2 do
  use GenServer

  def start_link([s, w]) do
    GenServer.start_link(__MODULE__, [s, w])
  end

  @impl true
  def init([s, w]) do
    # Task.async(fn-> gossip(s,w,1000) end)
    # Task.async(fn-> run() end)
    # 0 for count
    # last s for name
    {:ok, {s, w, 0, s}}
  end

  # def gossip(s,w) do
  def handle_cast({:send, {received_s, received_w}}, {s, w, count, my_name}) do
    # IO.puts("#{inspect(self())} #{received_s} #{received_w}")
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {_, neighbour_pid} = Enum.random(state)

      if neighbour_pid != self() and neighbour_pid != nil do
        GenServer.cast(neighbour_pid, {:receive, {received_s, received_s}})
      else
        # incase if the random pid is self, resend the incoming msg
          # if neighbour_pid == self() do
      GenServer.cast(self(), {:send, {received_s, received_w}})
          # else
          #   Process.kill(self(), :kill)
          # end

      end
    else
      # incase the map is not initialized

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
    IO.puts("#{inspect(self())} #{received_s} #{received_w} #{count}")

    if count >= 3 do
      # V.VampireState.print(V.VampireState)

      GenServer.call(KV.Registry, {:updateMap,my_name})
      new_list_of_nodes = GenServer.call(PushTheGossip.Convergence,{:i_heard_it_remove_me, my_name })

      #IO.puts "new_list_of_nodes for #{my_name}"
      #IO.inspect new_list_of_nodes
      if new_list_of_nodes != [] do
        GenServer.cast(self(), {:send, {s, w}})
      end
      #Process.exit(self(), :kill)
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
