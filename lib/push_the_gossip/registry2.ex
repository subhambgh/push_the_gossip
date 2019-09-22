defmodule V.VampireState do
  @moduledoc """
  The Genserver module that stores Vampire Numbers...

  Initialized by V.Supervisor, the async tasks call the push function to add vampire numbers with it's fangs.
  """

  use GenServer

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    vampires = %{}
    {:ok, vampires}
  end

  @doc """
  Prints all the vampire numbers recieved, by calling handle_call ({:print}, ...) ...

  ## Example
      iex> V.VampireState.print(V.VampireState)
  """
  def print(server) do
    GenServer.call(server, {:print})
  end

  @doc """
  Stores the Vampire Numbers by pushing them in the "vampire" map. Calls handle_cast({:push, n, fangs}, ...).
  ## Examples

      iex> V.VampireState.push(V.VampireState, 1260, [ {"21","60"} ])

  """
  def push(server, n, fangs) do
    GenServer.cast(server, {:push, n, fangs})
  end

  @doc """
  Sorts and prints the vampire map... Called by the V.VampireState.print() function

  """
  @impl true
  def handle_call({:print}, _, vampires) do
    Enum.each(Enum.sort(vampires), fn {k, v} ->
      IO.puts(
        "#{inspect(k)} #{inspect(v)}"
        # v
        # |> Enum.flat_map(&[elem(&1, 0), elem(&1, 1)])
        # |> List.insert_at(0, k)
        # |> Enum.join(" ")
      )
    end)

    {:reply, :printed, vampires}
  end

  @doc """
  Pushes the vampire numbers in the vampire map... Called using V.VampireState.push()
  """
  @impl true
  def handle_cast({:push, n, fangs}, vampires) do
    IO.puts("#{inspect(n)} #{inspect(fangs)}")
    vampires = Map.put(vampires, n, fangs)
    {:noreply, vampires}
  end
end
