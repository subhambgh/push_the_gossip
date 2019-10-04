defmodule AdjacencyHelper do
  def getAdjList(topology,numNodes,name,nodeList) do
    case topology do
      "full" ->
        #adj_list = Enum.map(1..numNodes, fn i -> i end)
        #adj_list -- [name]
        [name]
      "line" ->
        cond do
          name == 1 ->
            [name+1]
          name == numNodes ->
            [name - 1]
          true ->
            [name - 1, name + 1]
        end
      "3Dtorus" ->
        #nodeList is list_of_neighbours
        Enum.at(nodeList, name - 1)
    end
  end

  def getAdjListForRand2DAndHoneycombs(topology,name,nodeList,map_of_neighbours,i) do
    case topology do
      "rand2D" ->
        map_of_neighbours[name]
      "honeycomb" ->
        map_of_neighbours[
                 [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)]
               ]
      "randhoneycomb" ->
        map_of_neighbours[
                 [Enum.at(Enum.at(nodeList, i - 1), 0), Enum.at(Enum.at(nodeList, i - 1), 1)]
               ]
    end
  end

  def getNodeList(topology,numNodes) do
      case topology do
        "full" ->
          []
          #Enum.map(1..numNodes, fn i -> i end)

        "line" ->
          []
          #Enum.map(1..numNodes, fn i -> i end)

        "rand2D" ->
          generate_random_2D(numNodes,[])

        "honeycomb"->
          outer_loop(0,numNodes,%{})

        "randhoneycomb"->
          random_honeycomb(outer_loop(0,numNodes,%{}))

      end
  end

  def getNodeListFor3D(_numNodes, rowcnt, rowcnt_square) do
    for x <- 1..rowcnt,
        y <- 1..rowcnt,
        z <- 1..rowcnt,
        do: Enum.uniq(List.flatten(nodeListMaker(x, y, z, rowcnt, rowcnt_square)))
  end

  ###### Helper Functions #############
  # ======== Functions for Random 2D Neighbour Generation End =================#

  def generate_random_2D(numNodes, node_list) do
    if length(node_list) == numNodes do
      node_list
    else
      #new_node_list = Enum.uniq([ [:rand.uniform(10) / 10, :rand.uniform(10) / 10] | node_list])
      new_node_list = [ [:rand.uniform(), :rand.uniform()] | node_list]
      generate_random_2D(numNodes, new_node_list)
    end
  end

  def distance(x, y) do
    :math.sqrt( :math.pow((Enum.at(x,0)-Enum.at(y,0)), 2) + :math.pow((Enum.at(x,1)-Enum.at(y,1)), 2))
  end

  def generate_neighbours_for_random2D(nodeCoordinateList) do
      nodeCoordinateList
      |> Enum.map(fn pos ->
        {pos, Enum.filter(List.delete(nodeCoordinateList, pos), &(distance(pos, &1) <= 0.1))}
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

    def generate3d(_numNodes, rowcnt, rowcnt_square) do
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
      list_of_nodes = Enum.map(adjacency_map, fn {k, _v} -> k end)

      #IO.inspect(length(list_of_nodes))

      add_random_nodes(0, list_of_nodes, adjacency_map)
    end

    # ======= Functions for Random Honeycomb Neighbour Generation End ===============#
end
