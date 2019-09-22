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

  def gossip_full(numNodes) do
    for i <- 1..numNodes do
      GenServer.cast(KV.Registry, {:create, i})
    end
  end

  def gossip_line(numNodes) do
    for i <- 1..numNodes do
      GenServer.cast(KV.Registry, {:create, i, numNodes})
    end
  end

  def push_sum_full(numNodes) do
    for i <- 1..numNodes do
      GenServer.call(KV.Registry, {:create_push_full, i})
    end

    # initialize
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {_, random_pid} = Enum.random(state)
      GenServer.cast(random_pid, {:transrumor, {0, 0}})
      # run()
    end
  end
  
  def push_sum_line(numNodes) do
    IO.puts("really up here #{numNodes}")
    for i <- 1..numNodes do
      IO.puts("up here #{numNodes}")
      GenServer.call(KV.Registry, {:create_push_line, i, numNodes})
    end

    # initialize
    state = GenServer.call(KV.Registry, {:getState})

    if state != %{} do
      {_, random_pid} = Enum.random(state)
      GenServer.cast(random_pid, {:transrumor, {0, 0}})
      # run()
    end
  end

  def run() do
    run()
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
    
    { _, _, adj_list} = state

    {:reply, Map.fetch(adj_list, myName), state}
  end

  @impl true
  def handle_cast({:create_gossip_full, name}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.Bucket, 0})
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs, adj_list}}
    end
  end

  @impl true
  def handle_cast({:create_gossip_line, name, numNodes}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.Bucket, 0})

      case name do
        1 ->
          adj_list = Map.put(adj_list, name, [name + 1])

        numNodes ->
          adj_list = Map.put(adj_list, name, [name - 1])

        _ ->
          adj_list = Map.put(adj_list, name, [name - 1, name + 1])
      end

      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)

      {:noreply, {names, refs, adj_list}}
    end
  end

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

  @impl true
  def handle_cast({:create_push_line, [name, numNodes]}, {names, refs, adj_list}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs, adj_list}}
    else
      {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, {KV.PushSumLine, [name, 1]})

      #IO.puts("Abe #{name} #{numNodes} aa gaya")
      adj_list =  cond do
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
      #IO.puts("#{name}")
      #IO.inspect(adj_list)
      {:noreply, {names, refs, adj_list}}
    end
  end

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
