defmodule KV.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @impl true
  def init(:ok) do
    children = [
      {KV.Registry, name: KV.Registry},
      {KV.FailureHelper, name: KV.FailureHelper},
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one},
      {PushTheGossip.Convergence, name: PushTheGossip.Convergence}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
