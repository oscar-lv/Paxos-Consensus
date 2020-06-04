defmodule SRSTest do
  # Local setup helper
  def local_setup do
    pid1 = SRS.start(:p1, [:p1, :p2, :p3, :p4, :p5])
    pid2 = SRS.start(:p2, [:p1, :p2, :p3, :p4, :p5])
    pid3 = SRS.start(:p3, [:p1, :p2, :p3, :p4, :p5])
    pid4 = SRS.start(:p4, [:p1, :p2, :p3, :p4, :p5])
    pid5 = SRS.start(:p5, [:p1, :p2, :p3, :p4, :p5])
    {pid1, pid2, pid3, pid4, pid5}
  end

  # Distributed name helper
  defp dist_name(name, host) do
    name2 = String.to_atom(name <> "@" <> host)
    name2
  end

  # Distributed setup helper
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

  #  Kill participant
  defp kill(participants) do
    for pid <- participants, do: Process.exit(pid, :kill)
  end

  # Randomly delayed kill helper
  defp rdkill(pid) do
    Process.sleep(Enum.random(1..5))
    Process.exit(pid, :kill)
  end

  # Random delayed kill
  defp rdelayed_kill(participants) do
    for pid <- participants, do: rdkill(pid)
  end

  # Test a simple reservation and get status
  def test_simple(setup) do
    {pid1, pid2, pid3, pid4, pid5} = setup
    SRS.reserve(pid1, {:seat1, 'Mr.White'})
    Process.sleep(300)
    IO.puts('State:')
    SRS.gets(pid1)
    Process.sleep(50)
    IO.puts('Seat status:')
    SRS.status(pid1, :seat1)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
    self()
  end

  # Test 5 reservations and get status
  def test_simple_5(setup) do
    {pid1, pid2, pid3, pid4, pid5} = setup
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

  #  Test that a seat can not be booked twice
  def test_double_booking(setup) do
    {pid1, pid2, pid3, pid4, pid5} = setup
    SRS.reserve(pid2, {:seat1, 'Mr.White'})
    Process.sleep(600)
    SRS.reserve(pid3, {:seat1, 'Mr.Brown'})
    Process.sleep(600)
    SRS.status(pid1, :seat1)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end

  # Test that 2 concurrent reservations result in consensus
  def test_2_concurrent(setup) do
    {pid1, pid2, pid3, pid4, pid5} = setup
    SRS.reserve(pid2, {:seat1, 'Mr.White'})
    SRS.reserve(pid3, {:seat1, 'Mr.Brown'})
    Process.sleep(1000)
    SRS.status(pid1, :seat1)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end

  # Test that many concurrent reservations result in consensus
  def test_many_concurrent(setup) do
    {pid1, pid2, pid3, pid4, pid5} = setup
    SRS.reserve(pid2, {:seat1, 'Mr.White'})
    SRS.reserve(pid3, {:seat1, 'Mr.Brown'})
    SRS.reserve(pid1, {:seat1, 'Mr.Pink'})
    Process.sleep(1000)
    SRS.status(pid1, :seat1)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end

  # Test that a minority of failures and concurrency result in consensus
  def cascading_minority(setup) do
    {pid1, pid2, pid3, pid4, pid5} = setup
    SRS.reserve(pid1, {:seat1, 'Mr Brown'})
    SRS.reserve(pid2, {:seat1, 'Mr.White'})
    Process.sleep(100)
    kill([pid1, pid2])
    IO.puts("killed 1 and 2")
    Process.sleep(100)
    SRS.reserve(pid5, {:seat4, 'Mr.Orange'})
    SRS.reserve(pid5, {:seat5, 'Mr.Blonde'})
    Process.sleep(2000)
    SRS.gets(pid5)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end

  # Test that a minority of random delayed failures and concurrency result in consensus
  def cascading_random_delays(setup) do
    {pid1, pid2, pid3, pid4, pid5} = setup
    SRS.reserve(pid1, {:seat1, 'Mr Brown'})
    SRS.reserve(pid2, {:seat2, 'Mr.White'})
    Process.sleep(100)
    rdelayed_kill([pid1, pid2])
    IO.puts("killed 1 and 2 with random delays")
    Process.sleep(100)
    SRS.reserve(pid4, {:seat4, 'Mr.Orange'})
    SRS.reserve(pid5, {:seat5, 'Mr.Blonde'})
    Process.sleep(1900)
    SRS.gets(pid4)
    Process.sleep(100)
    kill([pid1, pid2, pid3, pid4, pid5])
  end
end
