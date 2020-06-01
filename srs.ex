defmodule SRS do
  def reserve(pid, {seat, person}) do
    send(pid, {:reserve, {seat, person}})
  end

  def status(seat) do
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
          status = Map.get(state.seats, seat)
          IO.puts("status #{status}")

          case status do
            status when status == :none ->
              Paxos.propose(state.paxos, {seat, person})
              Paxos.start_ballot(state.paxos)

              state

            status when status != :none ->
              IO.puts("#{inspect(seat)} was already booked by #{status}")
              state
          end

        # State getter
        {:get} ->
          IO.inspect(state)
          state

        {:decide, {seat, person}} ->
          IO.inspect({:decide, {seat, person}})
          state = %{state | seats: Map.replace!(state.seats, seat, person)}
          state

        # Propose Acceptance
        {:proposed, {:val, value}} ->
          state = %{state | value: value}
          # IO.puts('#{state.name}: New proposal accepted = #{value}')
          state

        _ ->
          state
      end

    run(state)
  end
end
