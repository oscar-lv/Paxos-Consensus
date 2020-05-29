defmodule SRS do
  def reserve(pid, seat) do
    send(pid, {:reserve, seat})
    Paxos.propose(pid, seat)
    result = Paxos.start_ballot(pid)
    result
  end

  def status(seat) do
  end

  def start(name, participants, upper_layer) do
    pid = spawn(SRS, :init, [name, participants, upper_layer])
  end

  def init(name, participants, upper_layer) do
    paxos = Paxos.start(name, neighbours, upper_layer)

    state = %{
      name: name,
      paxos: paxos
      seats: %{:seat1: :none, :seat2: :none}
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
          Paxos.propose(sate.paxos, seat)
          Paxos.start_ballot(sate.paxos)
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
