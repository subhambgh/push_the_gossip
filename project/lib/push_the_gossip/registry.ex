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
    value = names[name]
    {:reply, value, state}
  end


  def handle_call({:reverse_lookup, pid}, _from, state) do
      {names, _, _} = state
      value = names
              |> Enum.find(fn {key, val} -> val == pid end)
              |> elem(0)

    {:reply, value, state}
  end



  #implemented for full topologies only
  def handle_call({:updateMap,nameToDelete},_from, {names, refs, adj_list}) do
    #IO.inspect(names)
    if map_size(names) != 0 do
      names = Map.delete(names, nameToDelete)
      refs = Map.delete(refs, nameToDelete)
      {:reply, {names, refs, adj_list}, {names, refs, adj_list}}
    else
      #IO.puts("converzed")
      {:reply, {names, refs, adj_list}, {names, refs, adj_list}}
    end
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call({:updateAdjList, nameToDelete}, _from, {names, refs, adj_list}) do
    # suppose nameToDelete = 2
    # 2=> [3,1]
    # 3 => [4,2] #so we have to delete 2 in the here
    # 1=> [2] #and here
    # IO.inspect(adj_list)

    if(adj_list == %{} || adj_list == nil) do
      Enum.each(names, fn {k, v} ->
        Process.exit(v, :kill)
      end)
    end

    # suppose nameToDelete = 2
    # 2=> [3,1]
    # 3 => [4,2] #so we have to delete 2 in the here
    # 1=> [2] #and here

    if adj_list[nameToDelete] == nil do
      {:reply, {names, refs, adj_list}, {names, refs, adj_list}}
    else
      # [3,1]
      keyList = adj_list[nameToDelete]
      # IO.puts("---- ")
      # IO.inspect(nameToDelete)
      # IO.inspect(keyList)
      adj_list = Map.delete(adj_list, nameToDelete)
      # for each [3,1] , let say for 3
      adj_list =
        Enum.reduce(keyList, adj_list, fn key, acc ->
          # [4,2]
          elementsList = adj_list[key]
          # IO.inspect(_)
          # IO.inspect(adj_list)
          if elementsList == nil do
            acc
          else
            # [4]
            updatedElementList = List.delete(elementsList, nameToDelete)
            # add [3 => [4]]
            Map.put(acc, key, updatedElementList)
          end
        end)

      {:reply, {names, refs, adj_list}, {names, refs, adj_list}}
    end
  end

  @impl true
  def handle_call({:getState}, _from, {names, refs, adj_list}) do
      {:reply, names, {names, refs, adj_list}}
  end

  # ======================= Gossip Full Start ================================#

  @impl true
  def handle_call({:create_gossip, state},_from, {names, refs, adj_list}) do
    name = state.name
    if Map.has_key?(names, name) do
      {:reply, {names, refs, adj_list},{names, refs, adj_list}}
    else
      #{:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {Gossip, state})
      {:ok, pid} = GenServer.start_link(Gossip, state)
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:reply,{names, refs, adj_list}, {names, refs, adj_list}}
    end
  end

  # ======================= Gossip Full End ================================#


  # ======================= Gossip Random 2D Start ================================#

  @impl true
  def handle_cast({:create_gossip_random_2D, [name, neighbours]}, {names, refs, adj_list}) do
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

  # ======================= Gossip Honeycomb Start ================================#

  @impl true
  def handle_cast(
        {:create_gossip_honeycomb, [name, numNodes, neighbours]},
        {names, refs, adj_list}
      ) do
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

  # ===================== Gossip Honeycomb End ==============================#

  # ===================== Push Sum Full Start ==============================#

  @impl true
  def handle_cast({:create_push_sum, name}, {names, refs, adj_list}) do
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



  # ===================== Push Sum Full Start ==============================#

  @impl true
  def handle_cast({:create_push_full, name}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = GenServer.start_link(PushSum.Full, [name, 1])
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Push Sum Full End ==============================#

  # ===================== Push Sum Line Start ==============================#

  @impl true
  def handle_cast({:create_push_line, [name]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = GenServer.start_link(PushSum.Rest, [name, 1, name])

      # adj_list =
      #   cond do
      #     name == 1 ->
      #       Map.put(adj_list, name, [name + 1])

      #     name == numNodes ->
      #       Map.put(adj_list, name, [name - 1])

      #     true ->
      #       Map.put(adj_list, name, [name - 1, name + 1])
      #   end

      adj_list = []

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
  def handle_cast(
        {:create_push_random_2D, [name, number_for_s]},
        {names, refs, adj_list}
      ) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} =
      GenServer.start_link(PushSum.Rest, [number_for_s, 1, name])

      #adj_list = Map.put(adj_list, name, neighbours)
      #adj_list = []
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)

      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Push Sum Random 2D End ==============================#

  # ======================= Push Sum 3D Start ================================#

  @impl true
  def handle_cast({:create_push_3D, [name]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.PushSumLine, [name, 1, name]})
      #adj_list = Map.put(adj_list, name, neighbours)
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Push Sum 3D End ==============================#

 # ======================= Push Sum Honeycomb Start ================================#

  @impl true
  def handle_cast({:create_push_honeycomb, [s, neighbours, name]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.PushSumLine, [s, 1, name]})
      #adj_list = Map.put(adj_list, name, neighbours)
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs, adj_list}}
    end
  end

  # ===================== Push Sum Honeycomb End ==============================#



  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, {names, refs, adj_list}) do
    # handle failure according to the reason
    #{name, refs} = Map.pop(refs, ref)
    #names = Map.delete(names, name)
    #IO.puts("killed #{IO.inspect name} with reason "<>inspect(reason))
    #IO.inspect name, charlists: :as_lists
    # if map_size(names) == 0 do
    #   send(self(), {:justfinish})
    # end

    {:noreply, {names, refs, adj_list}}
  end

  # ======== Functions for Line Neighbour Generation =================#

  def make_a_line (numNodes) do

    Enum.map(1..numNodes, fn name ->

        cond do
          name == 1 ->
            [name + 1]

          name == numNodes ->
            [name - 1]

          true ->
            [name - 1, name + 1]
        end


      end)


  end
  # ======== Functions for Line Neighbour Generation =================#

  # ======== Functions for Random 2D Neighbour Generation =================#

  def generate_random_2D(numNodes, node_list) do
    if length(node_list) == numNodes do
      node_list
    else
      new_node_list = Enum.uniq([ [:rand.uniform(10000) / 10000, :rand.uniform(10000) / 10000] | node_list])
      generate_random_2D(numNodes, new_node_list)
    end
  end

  def distance(x, y) do
    #IO.inspect [x, y]
    :math.sqrt( :math.pow((Enum.at(x,0)-Enum.at(y,0)), 2) + :math.pow((Enum.at(x,1)-Enum.at(y,1)), 2))
  end

  def generate_neighbours_for_random2D(node_coordinates) do

    #neighbours = generate_empty_neighbour_list_for_random_2D(numNodes

    #map_of_neighbours = for i <- 1..numNodes, into: %{}, do: {i, []}

    node_coordinates
    |> Enum.map(fn pos ->
      {pos, Enum.filter(List.delete(node_coordinates, pos), &(distance(pos, &1) < 0.1))}
    end)
    |> Map.new()
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
    for x <- 1..rowcnt,
        y <- 1..rowcnt,
        z <- 1..rowcnt,
        do: Enum.uniq(List.flatten(nodeListMaker(x, y, z, rowcnt, rowcnt_square)))
  end

  # ======= Functions for 3D torus Neighbour Generation End ===============#

  # ======= Functions for Honeycomb Neighbour Generation ===============#

  def add_edges(point_a, point_b, adjacency_map) do
    neighbour_of_a = Enum.uniq([point_b | adjacency_map[point_a]])

    neighbour_of_b = Enum.uniq([point_a | adjacency_map[point_b]])

    adjacency_map = Map.put(adjacency_map, point_a, neighbour_of_a)

    adjacency_map = Map.put(adjacency_map, point_b, neighbour_of_b)

    adjacency_map
  end

  def connections_of_hexagons(list_of_points, adjacency_map) do
    adjacency_map =
      add_edges(Enum.at(list_of_points, 0), Enum.at(list_of_points, 1), adjacency_map)

    adjacency_map =
      add_edges(Enum.at(list_of_points, 0), Enum.at(list_of_points, 2), adjacency_map)

    adjacency_map =
      add_edges(Enum.at(list_of_points, 1), Enum.at(list_of_points, 3), adjacency_map)

    adjacency_map =
      add_edges(Enum.at(list_of_points, 2), Enum.at(list_of_points, 4), adjacency_map)

    adjacency_map =
      add_edges(Enum.at(list_of_points, 3), Enum.at(list_of_points, 5), adjacency_map)

    adjacency_map =
      add_edges(Enum.at(list_of_points, 4), Enum.at(list_of_points, 5), adjacency_map)
  end

  def add_point_to_adjacency_map(point, adjacency_map) do
    adjacency_map =
      cond do
        Map.has_key?(adjacency_map, point) == false -> Map.put(adjacency_map, point, [])
        true -> adjacency_map
      end
  end

  def make_hexagons_nodes(hexagon_x, hexagon_y, numNodes, adjacency_map) do

    #IO.puts "Creating hexagon #{hexagon_x}, #{hexagon_y} "

    offset = if rem(hexagon_y, 2) == 0, do: 0, else: 1

    point_1 = [hexagon_x * 2 + 1 + offset, hexagon_y * 2]

    point_2 = [hexagon_x * 2 + offset, hexagon_y * 2 + 1]

    point_3 = [hexagon_x * 2 + 2 + offset, hexagon_y * 2 + 1]

    point_4 = [hexagon_x * 2 + offset, hexagon_y * 2 + 2]

    point_5 = [hexagon_x * 2 + 2 + offset, hexagon_y * 2 + 2]

    point_6 = [hexagon_x * 2 + 1 + offset, hexagon_y * 2 + 3]

    list_of_points = [point_1, point_2, point_3, point_4, point_5, point_6]

    initial_size = map_size(adjacency_map)
    # IO.puts "initial_size: #{initial_size}"

    adjacency_map = add_point_to_adjacency_map(point_1, adjacency_map)

    adjacency_map = add_point_to_adjacency_map(point_2, adjacency_map)

    adjacency_map = add_point_to_adjacency_map(point_3, adjacency_map)

    adjacency_map = add_point_to_adjacency_map(point_4, adjacency_map)

    adjacency_map = add_point_to_adjacency_map(point_5, adjacency_map)

    adjacency_map = add_point_to_adjacency_map(point_6, adjacency_map)

    final_size = map_size(adjacency_map)
    # IO.puts "final_size: #{final_size}"

    adjacency_map = connections_of_hexagons(list_of_points, adjacency_map)

    newNumNodes = numNodes - (final_size - initial_size)

    {newNumNodes, adjacency_map}
  end

  def inner_loop(i, j, numNodes, adjacency_map) do

    if j == i+1 or numNodes <= 0 do

      #IO.puts("Done with #{i}")
      {numNodes, adjacency_map}
    else
      # IO.puts("from inner loop #{i} #{j} #{numNodes}")

      {newNumNodes, new_adjacency_map} = make_hexagons_nodes(j, i, numNodes, adjacency_map)

      if newNumNodes <= 0 or i == j do
        {newNumNodes, new_adjacency_map}
      else
        # IO.puts("from inner loop 2nd part #{i} #{j} #{newNumNodes}")

        {newNumNodes2, new_adjacency_map} =
          make_hexagons_nodes(i, j, newNumNodes, new_adjacency_map)

        inner_loop(i, j + 1, newNumNodes2, new_adjacency_map)
      end
    end
  end

  def outer_loop(i, numNodes, adjacency_map) do

    if numNodes <= 0 do
      #IO.puts "Done"
      adjacency_map
    else
      # IO.puts("from outer_loop loop #{i} #{numNodes}")

      {newNumNodes, adjacency_map} = inner_loop(i, 0, numNodes, adjacency_map)

      outer_loop(i + 1, newNumNodes, adjacency_map)
    end
  end

  # ======= Functions for Honeycomb Neighbour Generation End ===============#

  # ======= Functions for Random Honeycomb Neighbour Generation ===============#

  def add_random_nodes(i, list_of_nodes, adjacency_map) do
    if i == length(list_of_nodes) do
      adjacency_map
    else
      # IO.puts "#{i}"

      node_to_add =
        Enum.random(
          (list_of_nodes -- [Enum.at(list_of_nodes, i)]) --
            adjacency_map[Enum.at(list_of_nodes, i)]
        )

      #IO.inspect(node_to_add)

      adjacency_map_new =
        Map.put(adjacency_map, Enum.at(list_of_nodes, i), [
          node_to_add | adjacency_map[Enum.at(list_of_nodes, i)]
        ])

      add_random_nodes(i + 1, list_of_nodes, adjacency_map_new)
    end
  end

  def random_honeycomb(adjacency_map) do
    list_of_nodes = Enum.map(adjacency_map, fn {k, v} -> k end)

    #IO.inspect(length(list_of_nodes))

    add_random_nodes(0, list_of_nodes, adjacency_map)
  end

end
