defmodule KV.Bucket2 do
  use GenServer

 def start_link([s,w]) do
   GenServer.start_link(__MODULE__,[s,w])
 end

 @impl true
 def init([s,w]) do
   #Task.async(fn-> run() end)
   #Task.async(fn-> gossip(s,w,1000) end)
   Task.async ( fn -> gossip() end)
   {:ok, {s,w,0}} #0 for count
 end

 def gossip() do

    receive do
      {:gossip, {received_s,received_w}} -> (
        state = GenServer.call(KV.Registry, {:getState})
        if (state !=%{}) do
          {_,neighbour_pid} = Enum.random(state)
          if (neighbour_pid != self()) do
            GenServer.cast(neighbour_pid,{:transrumor,{received_s,received_s}})
          end
        end
      )
    end

    gossip()

 end

 #def gossip(s,w) do
 """
 def handle_cast({:gossip, {received_s,received_w}}, {s,w,count}) do
   IO.puts("#inspect self()} #received_s} #received_w}")
   state = GenServer.call(KV.Registry, {:getState})
   if (state !=%{}) do
     {_,neighbour_pid} = Enum.random(state)
     if (neighbour_pid != self()) do
       GenServer.cast(neighbour_pid,{:transrumor,{received_s,received_s}})
     end
   end
   {:noreply,{s,w,count}}
 end
 """

# this is the receive
 @impl true
 def handle_cast({:transrumor, {received_s,received_w}}, {s,w,count}) do
   IO.puts("#{inspect self()} #{received_s} #{received_w} #{count}")
   old_ratio = s/w
   s = received_s + s
   w = received_w + w
   new_ratio = s/w
   s=s/2
   w=w/2
   change = abs(old_ratio - new_ratio)
   count = if change > :math.pow(10,-10), do: 0, else: count + 1
   if count>=3 do
     Process.exit(self(),:kill)
     {:noreply,{s,w,count}}
   else
     #gossip(s,w)
     send(self(),{:gossip, {s,w}})
     {:noreply,{s,w,count}}
   end
 end

 def run do
    if DynamicSupervisor.count_children(KV.BucketSupervisor)>0 do
      run()
    end
 end

 @impl true
 def handle_info({_ref,_},{s,w,count}) do
   IO.puts("handle_info")
   gossip()
 end

 @impl true
 def terminate(reason, {s,w,count}) do
    IO.inspect "Look! I'm dead. #{reason}"
    gossip()
 end

end
