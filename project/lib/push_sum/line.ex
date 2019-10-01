defmodule PushSum.Rest do
  use GenServer

  def start_link([s, w, name]) do
    GenServer.start_link(__MODULE__, [s, w, name])
  end

  @impl true
  def init([s, w, name]) do
    neighbours = []
    {:ok, {s, w, 0, name, neighbours}}
  end

  def handle_cast({:send, {received_s, received_w}}, {s, w, count, my_name, neighbours}) do
    
    if neighbours != [] or neighbours == nil do
      neighbour_pid = Enum.random(neighbours)
      if neighbour_pid != nil and Process.alive?(neighbour_pid) do
        sending_to = GenServer.call(KV.Registry, {:reverse_lookup, neighbour_pid})
        IO.puts("#{inspect my_name} sending_to #{inspect sending_to}")

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
    #IO.puts("#{inspect my_name} received_s = #{received_s} received_w =#{received_w}")
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
      #not sending call to send up here, cause its a cast
      #and we are using call below to updateAdjList
      
      # case GenServer.call(KV.Registry, {:getRandomNeighPidFromAdjList, my_name}) do
      #   nil -> nil
      #   [random_neighbour, random_neighbour_pid] ->
      #     GenServer.cast(random_neighbour_pid, {:receive, {received_s, received_w}})
      # end
      # _ = GenServer.call(KV.Registry, {:updateAdjList,my_name})

      GenServer.call(PushTheGossip.Convergence,{:i_heard_it_remove_me, my_name })
      if neighbours != [] do
        GenServer.cast(self(), {:send, {s, w}})
      end

      Process.exit(self(), :normal)
      {:noreply, {s, w, count, my_name, neighbours}}
    else
      GenServer.cast(self(), {:send, {s, w}})
      {:noreply, {s, w, count, my_name, neighbours}}
    end
  end

  @impl true
  def handle_cast({:update_neighbours, new_neighbours}, {s, w, count, my_name, neighbours}) do
    #IO.puts "Updated #{my_name} with #{inspect(new_neighbours)}"
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
