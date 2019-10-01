  defmodule PushSum.Full do
  use GenServer

  def start_link([s, w]) do
    GenServer.start_link(__MODULE__, [s, w])
  end

  @impl true
  def init([s, w]) do
    name = s
    neighbours = []
    {:ok, {s, w, 0, name, neighbours}}
  end

  def handle_cast({:send, {received_s, received_w}}, {s, w, count, my_name, neighbours}) do
    # IO.puts("#{inspect(self())} #{received_s} #{received_w}")
    #state = GenServer.call(KV.Registry, {:getState})
    
    if neighbours != [] do
      neighbour_pid = Enum.random(neighbours)
      if Process.alive?(neighbour_pid) do
        #sending_to = GenServer.call(KV.Registry, {:reverse_lookup, neighbour_pid})
        #IO.puts("#{my_name} sending_to #{sending_to}")

        GenServer.cast(neighbour_pid, {:receive, {received_s, received_s}})
      else
        #IO.puts("here ! #{my_name}")
        new_neighbours = neighbours -- [neighbour_pid]
        GenServer.cast(self(), {:send, {received_s, received_w}})
        {:noreply, {s, w, count, my_name, new_neighbours}}
      end
    else
      GenServer.cast(self(), {:send, {received_s, received_w}})
    end

    {:noreply, {s, w, count, my_name, neighbours}}
  end


  # this is the receive
  @impl true
  def handle_cast({:receive, {received_s, received_w}}, {s, w, count, my_name, neighbours}) do
    # IO.puts("#{inspect(self())} #{received_s} #{received_w} #{count}")
    old_ratio = s / w
    s = received_s + s
    w = received_w + w
    new_ratio = s / w
    s = s / 2
    w = w / 2
    change = abs(old_ratio - new_ratio)
    count = if change > :math.pow(10, -10), do: 0, else: count + 1
    #IO.puts("#{inspect my_name} #{change} #{count}")
    if count >= 3 do
      #GenServer.call(KV.Registry, {:updateMap,my_name})
      GenServer.call(PushTheGossip.Convergence,{:i_heard_it_remove_me, my_name })
      if neighbours != [] do
        GenServer.cast(self(), {:send, {s, w}})
      end
      #IO.puts("#{my_name} done #{inspect(neighbours)}")
      Process.exit(self(), :normal)
      {:noreply, {s, w, count, my_name, neighbours}}
    else
      #if neighbours != [] do
        GenServer.cast(self(), {:send, {s, w}})   
      #end
      {:noreply, {s, w, count, my_name, neighbours}}
    end
  end

  @impl true
  def handle_cast({:update_neighbours, new_neighbours}, {s, w, count, my_name, neighbours}) do
    
    {:noreply, {s, w, count, my_name, new_neighbours}}
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
