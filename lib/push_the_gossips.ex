defmodule KV.Bucket do
  use GenServer

 def start_link(count) do
   GenServer.start_link(__MODULE__,count,:init)
 end

 @impl true
 def init(count) do
   gossip()
   {:ok, count}
 end

 def gossip() do
   neighbour_pid = elem(Enum.random(GenServer.call(KV.Registry,:getState)),2)
   if (neighbour_pid != nil && neighbour_pid != self()) do
     GenServer.cast(neighbour_pid,{:transrumor,"rumor"})
   end
   gossip()
 end

# this is the receive
 @impl true
 def handle_cast({:transrumor, rumor}, count) do
   if(count < 10) do
     {:noreply, count+1}
   else
     #{:stop, reason, new_state}
     {:stop, :normal, count}
     {:noreply,"killed"}
   end
 end

end
