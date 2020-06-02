defmodule SRSTest do
  def test_setup do
    pid1 = SRS.start(:p1, [:p1, :p2, :p3, :p4, :p5])
    pid2 = SRS.start(:p2, [:p1, :p2, :p3, :p4, :p5])
    pid3 = SRS.start(:p3, [:p1, :p2, :p3, :p4, :p5])
    pid4 = SRS.start(:p4, [:p1, :p2, :p3, :p4, :p5])
    pid5 = SRS.start(:p5, [:p1, :p2, :p3, :p4, :p5])
    {pid1, pid2, pid3, pid4, pid5}
    # SRS.reserve(pid1, {:seat1, 'Mr.Brown'})
    # SRS.reserve(pid2, {:seat2, 'Mr.White'})
    # SRS.reserve(pid3, {:seat3, 'Mr.Pink'})
    # SRS.reserve(pid4, {:seat4, 'Mr.Orange'})
    # SRS.reserve(pid5, {:seat5, 'Mr.Blonde'})
    # SRS.reserve(pid5, {:seat5, 'Mr.Blonde'})
  end

  def test_simple do
    IO.puts('Test Simple')
    {pid1, pid2, pid3, pid4, pid5} = test_setup
    SRS.reserve(pid1, {:seat1, 'Mr.White'})
    Process.sleep(100)
    IO.puts('State:')
    SRS.gets(pid1)
    IO.puts('Seat status:')
    SRS.status(pid1, :seat1)
  end

  def test_double_booking do
    IO.puts('Test that a process can not double book')
    {pid1, pid2, pid3, pid4, pid5} = test_setup
    SRS.reserve(pid2, {:seat1, 'Mr.White'})
    SRS.reserve(pid3, {:seat1, 'Mr.Brown'})
    Process.sleep(60)
    SRS.status(pid1, :seat1)
  end

  def test_concurrent() do
    IO.puts('Test Concurrent')
  end

  def run_minority_non_leader_crash(name, participants, val) do
    IO.puts('Test Minority')
    # {cpid, pid} = init(name, participants, true)
    # send(cpid, :ready)

    # receive do
    #   :start ->
    #     IO.puts("#{inspect(name)}: started")
    #     Paxos.propose(pid, val)

    #     if name == (leader = (fn [h | _] -> h end).(participants)),
    #       do: Paxos.start_ballot(pid)

    #     to_kill = Enum.slice(List.delete(participants, leader), 0, div(length(participants), 2))

    #     if name in to_kill do
    #       Process.sleep(Enum.random(1..5))
    #       Process.exit(pid, :kill)
    #     end

    #     if not (name in to_kill) do
    #       {status, {val, _}} = retry(pid, 1000, 10)

    #       if status != :none,
    #         do: IO.puts("#{name}: decided #{inspect(val)}"),
    #         else: IO.puts("#{name}: No decision after 10 seconds")
    #     end
    # end

    # send(cpid, :done)

    # receive do
    #   :all_done ->
    #     kill_paxos(pid, name)
    #     send(cpid, :finished)
    # end
  end

  def cascading_random_delays() do
    IO.puts('Test Minority, Delays')

    # Paxos.start_ballot(pid)
    # Process.sleep(Enum.random(1..5))
    # Process.exit(pid, :kill)
  end
end
