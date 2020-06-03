defmodule SRSTest do
  def local_setup do
    pid1 = SRS.start(:p1, [:p1, :p2, :p3, :p4, :p5])
    pid2 = SRS.start(:p2, [:p1, :p2, :p3, :p4, :p5])
    pid3 = SRS.start(:p3, [:p1, :p2, :p3, :p4, :p5])
    pid4 = SRS.start(:p4, [:p1, :p2, :p3, :p4, :p5])
    pid5 = SRS.start(:p5, [:p1, :p2, :p3, :p4, :p5])
    {pid1, pid2, pid3, pid4, pid5}
  end

  def dist_name(name, host) do
    name2 = String.to_atom(name <> "@" <> host)
    name2
  end

  def dist_setup(host) do
    alice = dist_name("alice", host)
    bob = dist_name("bob", host)
    charlie = dist_name("charlie", host)
    david = dist_name("david", host)
    eddy = dist_name("eddy", host)
    pid1 = SRS.start(alice, [alice, bob, charlie, david, eddy])
    pid2 = SRS.start(bob, [alice, bob, charlie, david, eddy])
    pid3 = SRS.start(charlie, [alice, bob, charlie, david, eddy])
    pid4 = SRS.start(david, [alice, bob, charlie, david, eddy])
    pid5 = SRS.start(eddy, [alice, bob, charlie, david, eddy])
    {pid1, pid2, pid3, pid4, pid5}
  end

  defp kill(participants) do
    for pid <- participants, do: Process.exit(pid, :kill)
  end

  defp rdkill(pid) do
    Process.sleep(Enum.random(1..5))
    Process.exit(pid, :kill)
  end

  defp rdelayed_kill(participants) do
    IO.puts("radom")
    for pid <- participants, do: rdkill(pid)
  end

  def test_simple do
    {pid1, pid2, pid3, pid4, pid5} = local_setup()
    SRS.reserve(pid1, {:seat1, 'Mr.White'})
    Process.sleep(300)
    IO.puts('State:')
    SRS.gets(pid1)
    Process.sleep(50)
    IO.puts('Seat status:')
    SRS.status(pid1, :seat1)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end

  def test_simple_5 do
    {pid1, pid2, pid3, pid4, pid5} = local_setup
    Process.sleep(50)
    SRS.reserve(pid1, {:seat1, 'Mr.White'})
    Process.sleep(50)
    SRS.reserve(pid2, {:seat2, 'Mr.Brown'})
    Process.sleep(50)
    SRS.reserve(pid3, {:seat3, 'Mr.Pink'})
    Process.sleep(50)
    SRS.reserve(pid4, {:seat4, 'Mr.Orange'})
    Process.sleep(50)
    SRS.reserve(pid5, {:seat5, 'Mr.Blonde'})
    Process.sleep(50)
    SRS.reserve(pid5, {:seat5, 'Mr.Blonde'})
    Process.sleep(900)
    IO.puts('State:')
    SRS.gets(pid1)
    Process.sleep(50)
    IO.puts('Seat Status:')
    SRS.status(pid1, :seat1)
    SRS.status(pid1, :seat2)
    SRS.status(pid1, :seat3)
    SRS.status(pid1, :seat4)
    SRS.status(pid1, :seat5)

    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end

  def test_double_booking do
    {pid1, pid2, pid3, pid4, pid5} = local_setup
    SRS.reserve(pid2, {:seat1, 'Mr.White'})
    Process.sleep(60)
    SRS.reserve(pid3, {:seat1, 'Mr.Brown'})
    SRS.status(pid1, :seat1)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end

  def test_concurrent() do
    {pid1, pid2, pid3, pid4, pid5} = local_setup
    SRS.reserve(pid2, {:seat1, 'Mr.White'})
    SRS.reserve(pid3, {:seat1, 'Mr.Brown'})
    Process.sleep(100)
    SRS.status(pid1, :seat1)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end

  def run_minority_non_leader_crash() do
    {pid1, pid2, pid3, pid4, pid5} = local_setup
    SRS.reserve(pid1, {:seat1, 'Mr Brown'})
    SRS.reserve(pid2, {:seat1, 'Mr.White'})
    rdelayed_kill([pid1, pid2])
    SRS.reserve(pid5, {:seat5, 'Mr.Blonde'})
    SRS.reserve(pid4, {:seat4, 'Mr.Orange'})
    Process.sleep(500)
    SRS.gets(pid5)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end

  def cascading_random_delays() do
    IO.puts('Test Minority, Delays')

    # Paxos.start_ballot(pid)
    # Process.sleep(Enum.random(1..5))
    # Process.exit(pid, :kill)
  end
end
