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
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor,   KV.GossipFull)
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

  # ===================== Push Sum Line Start ==============================#

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
end
