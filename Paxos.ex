defmodule Paxos do

  def start(name,participants,upper_layer) do
    pid = spawn(Paxos, :init, [name, participants, upper_layer])
    :global.unregister_name(name)
    case :global.register_name(name, pid) do
      :yes -> pid
      :no  -> :error
    end
  end

  def propose(pid, value) do
    send(pid, {:input, :bc_send, value})
  end

  def start_ballot(pid) do
    # Hello
  end

end
