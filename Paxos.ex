# Defining the Paxos Module
defmodule Paxos do

  # Defining the start function, globally registering the spawned PID
  def start(name, participants, upper_layer) do
    #Paxos.start(:p1, [:p1,:p2], self)
    IO.puts("START")
    pid = spawn(Paxos, :init, [name, participants, upper_layer])
    :global.unregister_name(name)
    case :global.register_name(name, pid) do
      :yes -> pid
      :no  -> :error
    end
  end

  # Init function from Flooding layer
  def init(name, participants, upper_layer) do
    IO.puts("INIT")
    state = %{
        name: name,
        participants: participants,
        upper_layer: upper_layer
     }
     run(state)
  end

  def bc_send(bcast, msg) do
    send(bcast, {:input, :bc_send, msg})
  end

  # Propose Function
  def propose(pid, value) do
    # IO.puts("PROPOSE")
    # IO.inspect(pid)
    # IO.puts("proposed value : ")
    # IO.inspect({:input, :init_val, value})
    {:proposed, pid,value}
  end

  # Start Ballot Function
  def start_ballot(pid) do
    b_number = :rand.uniform(10)
    IO.puts('Ballot number #{b_number} Started by:')
    IO.inspect(pid)
  end

  def id_p(pid) do
    :global.whereis_name(pid)
  end

  # Dummy run
  defp run(state) do
    IO.puts("RUN")
    IO.puts("State is :")
    IO.inspect(state)
    my_pid = self()
    IO.puts("PID is :")
    IO.inspect(my_pid)
    state = receive do
      {:input, :bc_send, msg} ->
        state = %{ state | received: MapSet.put(state.name, msg) }
      for p <- state.participants do
        case :global.whereis_name(p) do
          :undefined -> :undefined
          pid -> send(pid, {:relay_msg, state.name})
        end
      end
    end
  end

end
