defmodule KV.Bucket do
  use GenServer

 def start_link(count) do
   GenServer.start_link(__MODULE__,count)
 end

 @impl true
 def init(count) do
   Task.async(fn-> gossip() end)
   {:ok, count}
 end

 def gossip() do
   state = GenServer.call(KV.Registry, {:getState})
   if (state !=%{}) do
     {_,neighbour_pid} = Enum.random(state)
     if (neighbour_pid != self()) do
       GenServer.cast(neighbour_pid,{:transrumor,"rumor"})
     end
   end
   gossip()
 end

# this is the receive
 @impl true
 def handle_cast({:transrumor, rumor}, count) do
   IO.inspect(count)
   if(count < 10) do
     {:noreply, count+1}
   else
     #send(self(), :kill_me_pls)
     Process.exit(self(),:kill)
     {:noreply,count+1}
   end
 end

 @impl true
 def handle_info(:kill_me_pls, state) do
    #{:stop, reason, new_state}
   {:stop, :normal, state}
 end

 @impl true
 def terminate(_, _state) do
    IO.inspect "Look! I'm dead."
 end

end
