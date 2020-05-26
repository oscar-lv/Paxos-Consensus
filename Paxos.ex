# Defining the Paxos Module
defmodule Paxos do

  # Defining the start function, globally registering the spawned PID
  def start(name, participants, upper_layer) do
    pid = spawn(Paxos, :init, [name, participants, upper_layer])
    :global.unregister_name(name)
    case :global.register_name(name, pid) do
      :yes -> pid
      :no  -> :error
    end
  end

  # Init function from Routing layer
  def init(name, participants) do
    bcast = FloodingBC.start(name, participants, self)
    state = %{
      name: name,
      bcast: bcast
    }
    run(state)
  end

  # Dummy run
  def run(state) do
    state
  end

  # Propose Function
  def propose(pid, value) do
    pid.value = value
    #send(pid, {:input, :bc_send, value})
  end

  # Start Ballot Function
  def start_ballot(pid) do
    b_number = :rand.uniform(n)
    # Hello
  end

end
