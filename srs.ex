defmodule SRS do
  #  Start spawn a single SRS process
  def start(name, participants) do
    pid = spawn(SRS, :init, [name, participants])
    pid
  end

  # Init of state and run
  def init(name, participants) do
    # Init underlying Paxos protocol
    paxos = Paxos.start(name, participants, self())

    state = %{
      name: name,
      paxos: paxos,
      seats: %{
        seat1: :free,
        seat2: :free,
        seat3: :free,
        seat4: :free,
        seat5: :free
      }
    }

    run(state)
  end

  # Reserve a seat for a person
  def reserve(pid, {seat, person}) do
    send(pid, {:reserve, {seat, person}})
  end

  # Get status of a seat
  def status(pid, seat) do
    send(pid, {:status, seat})
  end

  # State Getter
  def gets(pid) do
    send(pid, {:get})
  end

  # Run function
  defp run(state) do
    # IO.inspect(state)

    state =
      receive do
        # Seat reservation
        {:reserve, {seat, person}} ->
          IO.puts("#{state.name} received reserve for #{person}")
          status = Map.get(state.seats, seat)

          # Checking if seat is taken
          case status do
            status when status != :free ->
              IO.puts("#{inspect(seat)} was already booked by #{status}")
              state

            status when status == :free ->
              # IO.puts("#{state.name} proposed")
              Paxos.propose(state.paxos, {seat, person})
              Paxos.start_ballot(state.paxos)
              state
          end

          Process.sleep(300)
          state

        # Return status of seat in Map
        {:status, seat} ->
          stat = Map.get(state.seats, seat)
          IO.puts("#{seat} booked by #{stat}")
          state

        # State getter
        {:get} ->
          IO.inspect(state)
          state

        # Book seat if Paxos Consensus is reached
        {:decide, {seat, person}} ->
          # IO.inspect({:decide, {seat, person}})
          state = %{state | seats: Map.replace!(state.seats, seat, person)}
          state

        _ ->
          state
      end

    run(state)
  end
end
