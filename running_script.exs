IEx.Helpers.c "paxos.ex"

pid1 = Paxos.start(:p1, [:p1,:p2,:p3], self())
pid2 = Paxos.start(:p2, [:p1,:p2,:p3], self())
pid3 = Paxos.start(:p3, [:p1,:p2,:p3], self())
Paxos.propose(pid1, 90)
Paxos.start_ballot(pid1)
Process.sleep(20)
Paxos.gets(pid1)
Paxos.gets(pid2)
Paxos.gets(pid3)
