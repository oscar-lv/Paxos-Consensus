# Defining the Paxos Module
defmodule Paxos do
  # Defining the start function, globally registering the spawned PID
  def start(name, participants, upper_layer) do
    # pid1 = Paxos.start(:p1, [:p1,:p2,:p3], self)
    # pid2 = Paxos.start(:p2, [:p1,:p2,:p3], self)
    # pid3 = Paxos.start(:p3, [:p1,:p2,:p3], self)
    IO.puts("START")
    pid = spawn(Paxos, :init, [name, participants, upper_layer])
    :global.unregister_name(name)

    case :global.register_name(name, pid) do
      :yes -> pid
      :no -> :error
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
      ballot: :none,
      prepared: 0
    }

    run(state)
  end

  #  Propose Function
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
    IO.inspect(state)
    c_b = state.ballot
    # IO.puts("RUN")
    # IO.puts("State is :")
    # IO.inspect(state)
    my_pid = self()
    # IO.puts("PID is :")
    # IO.inspect(my_pid)
    state =
      receive do
        # Propose Acceptance
        {:proposed, value} ->
          state = %{state | value: value}
          IO.puts('#{state.name}: New proposal accepted = #{value}')
          state

        # Prepared Acceptance
        {:prepared, n_b, {b_old, v_old}} ->
          state = %{state | prepared: state.prepared + 1}

          IO.puts(
            '#{state.name} received with ballot number #{n_b}, we now have #{state.prepared} prepared participants'
          )

          if state.prepared > Enum.count(state.participants) / 2 do
            IO.puts('We got a majority')
            r = {:accept, self, n_b}

            for p <- state.participants, p != state.name do
              case :global.whereis_name(p) do
                pid -> send(pid, r)
              end
            end
          end

          state

        # Accepted Phase
        {:accepted, pid, n_b} ->
          IO.puts('New prepare from #{inspect(pid)}')
          state

        # Acceptance
        {:accept, pid, n_b} ->
          IO.puts('New ACCEPT from #{inspect(pid)}')
          state

        # Prepare Phase
        {:prepare, pid, n_b} ->
          r = {:prepare, pid, n_b}
          IO.puts('#{state.name} received : #{inspect(r)}')

          if pid == self do
            for p <- state.participants, p != state.name do
              case :global.whereis_name(p) do
                pid -> send(pid, r)
              end
            end
          end

          response = {:prepared, n_b, {state.ballot, state.value}}
          send(pid, response)
          IO.puts("#{state.name} sent #{inspect(response)} to #{inspect(pid)}")
          state
          # case n_b  do
          #   n_b when n_b > c_b ->
          #     IO.inspect(my_pid)
          #     state = %{ state | ballot: n_b }
          #     IO.puts("New ballot #{n_b}")
          #     state
          #   c_b when n_b <= c_b ->
          #     IO.puts('No ballot change')
          #     state
          # end

          # end
      end

    run(state)
  end
end
