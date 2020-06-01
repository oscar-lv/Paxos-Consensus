# Defining the Paxos Module
defmodule Paxos do
  # Defining the start function, globally registering the spawned PID
  def start(name, participants, upper_layer) do
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
      # Name of the process
      name: name,
      # Participant List
      participants: participants,
      # Upper Layer
      upper_layer: upper_layer,
      # Current Proposed Value - default :none
      value: :none,
      # Highest Ballot Recorded - default :none
      ballot: :none,
      # Store of others Responses - default  %{}
      responses: %{},
      # Result of last participated ballots
      last: {:none},
      # Number of prepared messages received
      prepared: 0,
      # Number of accepted messages received
      accepted: 0,
      #  Prepared Majority Boolean
      prep_quorum: false,
      # Accetped Majority Boolean
      acc_quorum: false
    }

    run(state)
  end

  #  Propose Function
  def propose(pid, value) do
    send(pid, {:proposed, {:val, value}})
  end

  # State Getter
  def gets(pid) do
    send(pid, {:get})
  end

  # Partial Election State Reset
  def reset_state(state) do
    state = %{
      state
      | acc_quorum: false,
        prep_quorum: false,
        prepared: 0,
        accepted: 0,
        responses: %{}
    }

    state
  end

  # This functions gets the rank of P for a ballot generation
  def rank_helper(el, list) do
    list_2 = Enum.with_index(list)
    map3 = Enum.into(list_2, %{})
    rank = map3[el] + 1
    rank
  end

  # This function generates a unique ballot number
  def ballot_generator(state) do
    n = Enum.count(state.participants)
    b0 = state.ballot
    b = if(b0 != :none, do: b0, else: 0)
    rank = rank_helper(state.name, state.participants)
    #  Unique Ballot Number generation
    ballot_number = rank + (div(b, n) + 1) * n
    ballot_number
  end

  # Start Ballot Function
  def start_ballot(pid) do
    send(pid, {:start, pid})
  end

  # Leader Propagation @ Prepare Phase Helpers
  def leader_propagate_prepare(state, pid, r) do
    # Leader Broadcast
    if pid == self() do
      # IO.puts('#{state.name} broadcasting PREPARE phase')

      for p <- state.participants, p != state.name do
        # IO.puts('#{state.name} broadcasting to #{p}')

        case :global.whereis_name(p) do
          :undefined ->
            :error_p_not_found

          pid ->
            send(pid, r)
        end
      end
    end
  end

  # Helper for Leader to store ballot states of quorum
  def update_responses(state, response) do
    case response do
      response when response == {:none} ->
        state = %{state | responses: Map.put(state.responses, 'none', 0)}
        state

      _ ->
        state = %{
          state
          | responses:
              Map.put(state.responses, Kernel.elem(response, 0), Kernel.elem(response, 1))
        }

        state
    end
  end

  # Handling of Prepare message
  def prepare_handler(state, new_ballot, pid) do
    # Send response to leader
    last = state.last
    b_old = Kernel.elem(last, 0)

    case new_ballot do
      new_ballot when last == {:none} ->
        response = {:prepared, new_ballot, last}
        send(pid, response)
        # IO.puts("#{state.name} sent #{inspect(response)} to #{inspect(pid)}")
        state

      new_ballot when new_ballot > b_old ->
        response = {:prepared, new_ballot, last}
        send(pid, response)
        # IO.puts("#{state.name} sent #{inspect(response)} to #{inspect(pid)}")
        # state = %{ state | ballot: new_ballot }
        state

      b_old when new_ballot <= b_old ->
        # IO.puts('No ballot change')
        state
    end
  end

  # Checking majority of Prepared
  def prepare_majority(state, new_ballot, proposed_value) do
    n_prepared = state.prepared
    prep_quorum = state.prep_quorum
    n_participants = Enum.count(state.participants)

    case state do
      state
      when n_prepared > n_participants / 2 and prep_quorum == false ->
        state = %{state | prep_quorum: true}
        # IO.puts('#{state.name} : Majority Reached in PREPARED Phase --> Starting ACCEPT phase')
        # Starting ACCEPT Phase
        r = {:accept, self(), new_ballot, proposed_value}
        broadcast(state, r)
        state

      _ ->
        state
    end
  end

  # Function to get the highest ballot recorded by Quorum
  def max_ballot_value(state) do
    responses = state.responses
    max_ballot = Enum.max(Map.keys(responses))
    max_ballot_value = responses[max_ballot]
    max_ballot_value
  end

  # Checking majority of Accept
  def accept_majority(state) do
    n_accepted = state.accepted
    n_participants = Enum.count(state.participants)
    acc_quorum = state.acc_quorum

    # If all :prepared messages are :none -> proposed value is sent, else the value for the highest recorded ballot is sent
    value = if(state.responses == %{'none' => 0}, do: state.value, else: max_ballot_value(state))

    # If Majority is reached, the decide phase starts
    case state do
      state when n_accepted > n_participants / 2 and acc_quorum == false ->
        state = %{state | acc_quorum: true}
        # IO.puts('#{state.name} : Majority Reached in ACCEPT Phase --> Starting DECIDE phase')
        # Starting DECIDE Phase
        r = {:decide, value}
        broadcast(state, r)
        state

      _ ->
        state
    end
  end

  def broadcast(state, message) do
    for p <- state.participants do
      case :global.whereis_name(p) do
        :undefined -> :error_p_not_found
        pid -> send(pid, message)
      end
    end
  end

  # Run function
  defp run(state) do
    b_old = if state.last != {:none}, do: Kernel.elem(state.last, 0), else: :none
    # v_old = if state.last != {:none}, do: Kernel.elem(state.last, 1), else: :none

    state =
      receive do
        # Propose Acceptance
        {:proposed, {:val, value}} ->
          state = %{state | value: value}
          # IO.puts('#{state.name}: New proposal accepted = #{value}')
          state

        # State getter
        {:get} ->
          IO.inspect(state)
          state

        {:start, pid} ->
          value = state.value

          #  Prohibit start if no value is proposed

          case value do
            value when value == :none ->
              IO.puts('No value proposed, ballot aborted')
              state

            value when value != :none ->
              state = reset_state(state)
              b_number = ballot_generator(state)
              # IO.puts('#{state.name} generated ballot number :#{b_number}')
              send(pid, {:prepare, pid, b_number})
              state
          end

        # Prepare Phase - START BALLOT
        {:prepare, pid, new_ballot} ->
          # Message Handling
          r = {:prepare, pid, new_ballot}
          leader_propagate_prepare(state, pid, r)
          # Received message
          # IO.puts('#{state.name} received : #{inspect(r)}')
          prepare_handler(state, new_ballot, pid)

        # Prepared Acceptance
        {:prepared, new_ballot, response} ->
          state = %{state | prepared: state.prepared + 1}

          # Prepared Majority Handler, ready to send out proposed value
          state = prepare_majority(state, new_ballot, state.value)
          state = update_responses(state, response)
          state

        # Accepted Phase
        {:accepted, _} ->
          state = %{state | accepted: state.accepted + 1}

          # IO.puts(
          #   '#{state.name}: New accepted , we now have #{state.accepted} accepted participants'
          # )

          # Here the decide gets propagated to other layers if majority is hit
          state = accept_majority(state)
          state

        # Decided Phase
        {:decide, val} ->
          # Notifiy upper layer
          # IO.puts('#{state.name} Decided on #{inspect(val)}')
          send(state.upper_layer, {:decide, val})
          state

        # Acceptance
        {:accept, pid, new_ballot, value} ->
          # IO.puts(
          #   'New ACCEPT received from #{inspect(pid)} for ballot #{new_ballot} and value #{value}'
          # )

          case new_ballot do
            new_ballot when b_old == :none or new_ballot > b_old ->
              state = %{state | last: {new_ballot, value}, ballot: new_ballot}
              send(pid, {:accepted, new_ballot})
              # IO.puts('#{state.name} : sent accepted to #{inspect(pid)}')
              state

            _ ->
              state
          end

        _ ->
          state
      end

    run(state)
  end
end
