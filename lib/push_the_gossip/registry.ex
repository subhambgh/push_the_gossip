defmodule KV.Registry do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    names = %{}
    refs = %{}
    adj_list = %{}
    {:ok, {names, refs, adj_list}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, state) do
    {names, _, _} = state
    {:reply, Map.fetch(names, name), state}
  end

  @impl true
  def handle_call({:getState}, _from, state) do
    {:reply, elem(state, 0), state}
  end

  @impl true
  def handle_call({:getAdjList, myName}, _from, state) do
    {_, _, adj_list} = state

    {:reply, Map.fetch(adj_list, myName), state}
  end

  # ======================= Gossip Full Start ================================#

  @impl true
  def handle_cast({:create_gossip_full, name}, {names, refs, adj_list}) do
    # IO.puts("Creating #{name}")
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.GossipFull)
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs, adj_list}}
    end
  end

  # ======================= Gossip Full End ================================#

  # ======================= Gossip Line Start ================================#

  @impl true
  def handle_cast({:create_gossip_line, [name, numNodes]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.GossipLine, [name]})

      adj_list =
        cond do
          name == 1 ->
            Map.put(adj_list, name, [name + 1])

          name == numNodes ->
            Map.put(adj_list, name, [name - 1])

          true ->
            Map.put(adj_list, name, [name - 1, name + 1])
        end

      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)

      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Gossip Line End ==============================#

  # ======================= Gossip Random 2D Start ================================#

  @impl true
  def handle_cast({:create_gossip_random_2D, [name, numNodes, neighbours]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.GossipLine, [name]})

      adj_list = Map.put(adj_list, name, neighbours)

      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)

      

      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Gossip Random 2D End ==============================#

  # ======================= Gossip 3D Start ================================#

  @impl true
  def handle_cast({:create_gossip_3D, [name, numNodes, neighbours]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.GossipLine, [name]})

      adj_list = Map.put(adj_list, name, neighbours)

      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)

      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Gossip 3D End ==============================#

  # ===================== Push Sum Full Start ==============================#

  @impl true
  def handle_cast({:create_push_full, name}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.Bucket2, [name, 1]})
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Push Sum Full End ==============================#

  # ===================== Push Sum Line Start ==============================#

  @impl true
  def handle_cast({:create_push_line, [name, numNodes]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.PushSumLine, [name, 1]})

      adj_list =
        cond do
          name == 1 ->
            Map.put(adj_list, name, [name + 1])

          name == numNodes ->
            Map.put(adj_list, name, [name - 1])

          true ->
            Map.put(adj_list, name, [name - 1, name + 1])
        end

      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      # IO.puts("#{name}")
      # IO.inspect(adj_list)
      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Push Sum Line End ==============================#

  # ======================= Push Sum Random 2D Start ================================#

  @impl true
  def handle_cast({:create_push_random_2D, [name, number_for_s, numNodes, neighbours]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.PushSumRandom2D, [number_for_s, 1, name]})

      adj_list = Map.put(adj_list, name, neighbours)

      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)

      

      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Push Sum Random 2D End ==============================#

  # ======================= Push Sum 3D Start ================================#

  @impl true
  def handle_cast({:create_push_3D, [name, numNodes, neighbours]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      IO.puts("creating #{name}")
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.PushSumLine, [name, 1]})

      adj_list = Map.put(adj_list, name, neighbours)
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)

      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Push Sum 3D End ==============================#

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs, adj_list}) do
    # handle failure according to the reason
    # IO.puts("killed")
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)

    if map_size(names) == 0 do
      send(self(), {:justfinish})
    end

    {:noreply, {names, refs, adj_list}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # ======== Functions for Random 2D Neighbour Generation =================#  

  def generate_random_2D(numNodes, node_list) do
    if length(node_list) == numNodes do
      node_list
    else
      new_node_list = [ [:rand.uniform(10) / 10, :rand.uniform(10) / 10] | node_list]
      generate_random_2D(numNodes, new_node_list)
    end
  end

  def distance(x, y) do
    #IO.inspect [x, y]
    round(:math.sqrt( :math.pow((Enum.at(x,0)-Enum.at(y,0)), 2) + :math.pow((Enum.at(x,1)-Enum.at(y,1)), 2)))
  end

  def generate_neighbours_for_random2D(numNodes, node_coordinates) do
    
    #neighbours = generate_empty_neighbour_list_for_random_2D(numNodes

    #map_of_neighbours = for i <- 1..numNodes, into: %{}, do: {i, []} 

    node_coordinates |> 
    Enum.map(fn pos -> {pos, Enum.filter(List.delete(node_coordinates,pos), &(distance(pos, &1) < 0.1))} end) |>
    Map.new()


  end


  # ======== Functions for Random 2D Neighbour Generation End =================#  

  # ======== Functions for 3D torus Neighbour Generation =================#  

  def coordinates_to_node_name(x, y, z, rowcnt, rowcnt_square) do
    [(x - 1) * rowcnt_square + (y - 1) * rowcnt + z]
  end

  def nodeListMaker(x, y, z, rowcnt, rowcnt_square) do
    node_neighbour_list = []

    node_neighbour_list = [
      cond do
        x != rowcnt -> coordinates_to_node_name(x + 1, y, z, rowcnt, rowcnt_square)
        true -> coordinates_to_node_name(1, y, z, rowcnt, rowcnt_square)
      end
      | node_neighbour_list
    ]

    # IO.inspect(node_neighbour_list)

    node_neighbour_list = [
      cond do
        y != rowcnt -> coordinates_to_node_name(x, y + 1, z, rowcnt, rowcnt_square)
        true -> coordinates_to_node_name(x, 1, z, rowcnt, rowcnt_square)
      end
      | node_neighbour_list
    ]

    # IO.inspect(node_neighbour_list)

    node_neighbour_list = [
      cond do
        z != rowcnt -> coordinates_to_node_name(x, y, z + 1, rowcnt, rowcnt_square)
        true -> coordinates_to_node_name(x, y, 1, rowcnt, rowcnt_square)
      end
      | node_neighbour_list
    ]

    # IO.inspect(node_neighbour_list)

    node_neighbour_list = [
      cond do
        x != 1 -> coordinates_to_node_name(x - 1, y, z, rowcnt, rowcnt_square)
        true -> coordinates_to_node_name(rowcnt, y, z, rowcnt, rowcnt_square)
      end
      | node_neighbour_list
    ]

    # IO.inspect(node_neighbour_list)

    node_neighbour_list = [
      cond do
        y != 1 -> coordinates_to_node_name(x, y - 1, z, rowcnt, rowcnt_square)
        true -> coordinates_to_node_name(x, rowcnt, z, rowcnt, rowcnt_square)
      end
      | node_neighbour_list
    ]

    # IO.inspect(node_neighbour_list)

    node_neighbour_list = [
      cond do
        z != 1 -> coordinates_to_node_name(x, y, z - 1, rowcnt, rowcnt_square)
        true -> coordinates_to_node_name(x, y, rowcnt, rowcnt, rowcnt_square)
      end
      | node_neighbour_list
    ]

    # IO.inspect(node_neighbour_list)
  end

  def generate3d(numNodes, rowcnt, rowcnt_square) do
    # IO.puts("#{rowcnt}")
    for x <- 1..rowcnt,
        y <- 1..rowcnt,
        z <- 1..rowcnt,
        do: Enum.uniq(List.flatten(nodeListMaker(x, y, z, rowcnt, rowcnt_square)))
  end

  # ======= Functions for 3D torus Neighbour Generation End ===============#  
end

