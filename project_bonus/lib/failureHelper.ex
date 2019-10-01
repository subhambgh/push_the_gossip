defmodule KV.FailureHelper do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok,opts)
  end

  @impl true
  def init(:ok) do
    failedNodeNames = []
    {:ok, failedNodeNames}
  end

  def handle_call({:getState},_from,state) do
    {:reply,state, state}
  end

  @impl true
  def handle_call({:gossip_failure,state},_from,failedNodeNames) do
    {nodeToFailName, nodeToFailPid} = Enum.random(state)
    #if !Enum.member?(failedNodeNames,nodeToFailName) do #still have to look at it
    if Process.alive?nodeToFailPid do
      #IO.puts("nodeToFailName1= #{inspect nodeToFailName}")
        Process.exit(nodeToFailPid,:normal)
        #failedNodeNames =failedNodeNames++nodeToFailName
      #{:reply, nodeToFailName,nodeToFailName }
     end
     #IO.puts("#{inspect nodeToFailPid}")
     {:reply,nodeToFailName,failedNodeNames++[nodeToFailName]}
  end

  @impl true
  def terminate(_, _state) do
    IO.inspect("Terminating KV.FailureHelper")
  end

end
