defmodule KV do
  use Application

  @impl true
  def start(_type, _args) do
    KV.Supervisor.start_link()
  end
end
