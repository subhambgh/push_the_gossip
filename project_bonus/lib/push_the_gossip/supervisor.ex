defmodule KV.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @impl true
  def init(:ok) do
    children = [
      {Registry,keys: :unique, name: :node_registry},
      {PushTheGossip.Convergence, name: PushTheGossip.Convergence}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
