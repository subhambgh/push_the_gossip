defmodule AdjacencyHelper do
  def getAdjList(topology,numNodes,name,nodeList) do
    adj_list =
    case topology do
      "gossip_full" ->
        Enum.map(1..numNodes, fn i -> i end)

      "gossip_line" ->
        cond do
          name == 1 ->
            [name+1]
          name == numNodes ->
            [name - 1]
          true ->
            [name - 1, name + 1]
        end

      "gossip_random_2D" ->
        generate_neighbours_for_random2D(name,nodeList)
    end
  end

  def getNodeList(topology,numNodes) do
    nodeList =
      case topology do
        "gossip_full" ->
          Enum.map(1..numNodes, fn i -> i end)

        "gossip_line" ->
          Enum.map(1..numNodes, fn i -> i end)

        "gossip_random_2D" ->
          nodeList = generate_random_2D(numNodes,[])
      end
  end

  # ======== Functions for Random 2D Neighbour Generation End =================#

  def generate_random_2D(numNodes, node_list) do
    if length(node_list) == numNodes do
      node_list
    else
      new_node_list = Enum.uniq([ [:rand.uniform(10000) / 10000, :rand.uniform(10000) / 10000] | node_list])
      generate_random_2D(numNodes, new_node_list)
    end
  end

  def distance(x, y) do
    :math.sqrt( :math.pow((Enum.at(x,0)-Enum.at(y,0)), 2) + :math.pow((Enum.at(x,1)-Enum.at(y,1)), 2))
  end

  def generate_neighbours_for_random2D(name,nodeCoordinateList) do
    map =
      nodeCoordinateList
    |> Enum.map(fn pos ->
      {pos, Enum.filter(List.delete(nodeCoordinateList, pos), &(distance(pos, &1) < 0.1))}
    end)
    |> Map.new()

    map[name]
  end

  # ======== Functions for Random 2D Neighbour Generation End =================#

end
