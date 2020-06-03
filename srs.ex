defmodule SRS do
  def reserve(pid, {seat, person}) do
    send(pid, {:reserve, {seat, person}})
  end

  def status(pid, seat) do
    send(pid, {:status, seat})
  end

  def start(name, participants) do
    pid = spawn(SRS, :init, [name, participants])
    pid
  end

  # State Getter
  def gets(pid) do
    send(pid, {:get})
  end

  def init(name, participants) do
    paxos = Paxos.start(name, participants, self())

    state = %{
      name: name,
      paxos: paxos,
      seats: %{
        seat1: :none,
        seat2: :none,
        seat3: :none,
        seat4: :none,
        seat5: :none
      }
    }

    run(state)
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

          case status do
            status when status == :none ->
              # IO.puts("#{state.name} proposed")
              Paxos.propose(state.paxos, {seat, person})
              Paxos.start_ballot(state.paxos)
              state

            status when status != :none ->
              IO.puts("#{inspect(seat)} was already booked by #{status}")
              state
          end

          Process.sleep(300)
          state

        {:status, seat} ->
          stat = Map.get(state.seats, seat)
          IO.puts("#{seat} booked by #{stat}")
          state

        # State getter
        {:get} ->
          IO.inspect(state)
          state

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
