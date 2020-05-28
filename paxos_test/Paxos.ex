# Defining the Paxos Module
defmodule Paxos do
  # Defining the start function, globally registering the spawned PID
  def start(name, participants, upper_layer) do
    # pid1 = Paxos.start(:p1, [:p1,:p2,:p3], self)
    # pid2 = Paxos.start(:p2, [:p1,:p2,:p3], self)
    # pid3 = Paxos.start(:p3, [:p1,:p2,:p3], self)
    pid = spawn(Paxos, :init, [name, participants, upper_layer])
    :global.unregister_name(name)

    case :global.register_name(name, pid) do
      :yes -> pid
      :no -> :error
    end
  end

  # Init function from Flooding layer
  def init(name, participants, upper_layer) do
    state = %{
      name: name,
      participants: participants,
      upper_layer: upper_layer,
      value: 0,
      b_old_max: 0,
      ballot: :none,
      prepared: 0,
      prep_quorum: false,
      acc_quorum: false,
      accepted: 0
    }

    run(state)
  end

  #  Propose Function
  def propose(pid, value) do
    send(pid, {:proposed, value})
  end

  def gets(pid) do
    send(pid, {:get, 0})
  end

  # Start Ballot Function
  def start_ballot(pid) do
    b_number = :rand.uniform(10)
    IO.inspect(pid)
    send(pid, {:prepare, pid, b_number})
  end

  # Run function
  defp run(state) do
    #IO.inspect(state)
    b_old = state.ballot
    v_old = state.value
    state =
      receive do
        # Propose Acceptance
        {:proposed, value} ->
          state = %{state | value: value}
          IO.puts('#{state.name}: New proposal accepted = #{value}')
          state

        # State getter
        {:get, _} ->
          IO.inspect(state)
          state

         # Prepared Acceptance
        {:prepared, new_ballot, {_}} ->
          # TODO : include a none handler and accumulators for logic control
          state = %{state | prepared: state.prepared + 1}
          IO.puts(
            '#{state.name} received with ballot number #{new_ballot}, we now have #{state.prepared} prepared participants'
          )
          IO.puts('pre #{state.prep_quorum}')
          # Prepared Majority Handler
          if state.prepared > Enum.count(state.participants) / 2 and state.prep_quorum == false do
            state = %{state | prep_quorum: true}
            state
            IO.puts('post #{state.prep_quorum}')
            IO.puts('#{state.name} : Majority Reached in PREPARED Phase --> Starting ACCEPT phase')

            # Starting ACCEPT Phase
            r = {:accept, self(), new_ballot, v_old}
            for p <- state.participants do
              case :global.whereis_name(p) do
                pid -> send(pid, r)
              end
            end
          end
          state



        # Accepted Phase
        {:accepted, _} ->
          IO.puts('#{state.name}: New accepted')
          state

        # Acceptance
        {:accept, pid, new_ballot, value} ->
          IO.puts('New ACCEPT received from #{inspect(pid)} for ballot #{new_ballot} and value #{value}')
          case new_ballot do
            new_ballot when b_old == (:none) or new_ballot > b_old ->
              state = %{state | ballot: new_ballot, value: value}
              send(pid, {:accepted, new_ballot})
              IO.puts('#{state.name} : sent accepted to #{inspect(pid)}')
              state
              _ ->
              state
          end



        # Prepare Phase
        {:prepare, pid, new_ballot} ->

          # Message Handling
          r = {:prepare, pid, new_ballot}

          # Leader Broadcast
          if pid == self() do

            IO.puts('#{state.name} broadcasting PREPARE phase')
            for p <- state.participants, p != state.name do
              case :global.whereis_name(p) do
                pid -> send(pid, r)
              end
            end
          end

          # Received message
          IO.puts('#{state.name} received : #{inspect(r)}')

          # Send response to leader
          case new_ballot do
            new_ballot when b_old == (:none) ->
              response = {:prepared, new_ballot, {:none}}
              send(pid, response)
              IO.puts("#{state.name} sent #{inspect(response)} to #{inspect(pid)}")
              state
            new_ballot when new_ballot > b_old ->
              response = {:prepared, new_ballot, {b_old, v_old}}
              send(pid, response)
              IO.puts("#{state.name} sent #{inspect(response)} to #{inspect(pid)}")
              # state = %{ state | ballot: new_ballot }
              state
            b_old when new_ballot <= b_old ->
              IO.puts('No ballot change')
              state
          end

          # end
      end

    run(state)
  end
end
