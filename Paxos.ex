# Defining the Paxos Module
defmodule Paxos do

  # Defining the start function, globally registering the spawned PID
  def start(name, participants, upper_layer) do
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
    #send(bcast, {:input, :bc_send, msg})
  end

  # Dummy run
  defp run(state) do
    IO.puts("RUN")
    IO.puts("State is :")
    IO.inspect(state)
    my_pid = self()
    IO.puts("PID is :")
    IO.inspect(my_pid)
  end

  # Propose Function
  def propose(pid, value) do
    IO.puts("PROPOSE")
    IO.inspect(pid)
    IO.puts("proposed value : ")
    IO.inspect({:input, :init_val, value})
  end

  # Start Ballot Function
  def start_ballot(pid) do
    b_number = :rand.uniform(pid)
    # Hello
  end

end
