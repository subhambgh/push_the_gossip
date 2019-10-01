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


end
