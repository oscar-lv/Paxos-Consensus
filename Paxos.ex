# Defining the Paxos Module
defmodule Paxos do

  # Defining the start function, globally registering the spawned PID
  def start(name, participants, upper_layer) do
    #pid1 = Paxos.start(:p1, [:p1,:p2], self)
    #pid2 = Paxos.start(:p2, [:p1,:p2], self)
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
        upper_layer: upper_layer,
        value: 0,
        ballot_old: 10
     }
     run(state)
  end

  def bc_send(bcast, msg) do
    send(bcast, {:input, :bc_send, msg})
  end

  # Propose Function
  def propose(pid, value) do
    send(pid, {:proposed, value})
  end

  def gets(pid, value) do
    send(pid, {:started, value})
  end

  # Start Ballot Function
  def start_ballot(pid) do
    b_number = :rand.uniform(10)
    IO.inspect(pid)
    send(pid, {:prepare, pid, b_number})
  end

  def id_p(pid) do
    :global.whereis_name(pid)
  end

  def give_me_state(state) do
    IO.puts('givemestate:')
    IO.puts(state.name)
    IO.puts(state.value)
  end

  # Dummy run
  defp run(state) do
    c_b = state.ballot_old
    IO.puts("RUN")
    IO.puts("State is :")
    IO.inspect(state)
    my_pid = self()
    IO.puts("PID is :")
    IO.inspect(my_pid)
    state = receive do
      {:proposed, value} ->
        state = %{ state | value: value }
        IO.puts('New proposal accepted')
        for p <- state.participants, p != state.name do
          case :global.whereis_name(p) do
            :undefined -> :undefined
            pid -> propose(pid, value)
          end
        end
        IO.inspect(state)
        state

      {:started, value} ->
        state = %{ state | value: value }
        IO.puts('New proposal accepted')
        for p <- state.participants, p != state.name do
          case :global.whereis_name(p) do
            :undefined -> :undefined
            pid -> propose(pid, value)
          end
        end
        IO.inspect(state)
        state


      {:prepare, pid, n_b} ->
        IO.puts('New prepare from #{inspect pid}')
        case n_b  do
          n_b when n_b > c_b ->
            IO.inspect(my_pid)
            IO.puts("New ballot #{n_b}")
            state = %{ state | ballot_old: n_b }
          c_b when n_b <= c_b ->
            IO.puts('No ballot change')
        end
        state

      # end
    end
    run(state)
  end

end
