defmodule SRS do
  def reserve(pid, seat) do
    send(pid, {:reserve, seat})
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
      seats: 0
    }

    run(state)
  end

  # Run function
  defp run(state) do
    # IO.inspect(state)

    state =
      receive do
        # Seat reservation
        {:reserve, seat} ->
          Paxos.propose(state.paxos, seat)
          Paxos.start_ballot(state.paxos)
          state

        # State getter
        {:get} ->
          IO.inspect(state)
          state

        {:decide, {seat, person}} ->
          IO.inspect({:decide, {seat, person}})
          state = %{state | seats: {seat, person}}
          state

        # Propose Acceptance
        {:proposed, {:val, value}} ->
          state = %{state | value: value}
          # IO.puts('#{state.name}: New proposal accepted = #{value}')
          state
      end

    run(state)
  end
end
