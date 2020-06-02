IEx.Helpers.c("paxos.ex")

a = String.to_atom("alice@oscars-MacBook-Pro")
b = String.to_atom("bob@oscars-MacBook-Pro")
c = String.to_atom("charlie@oscars-MacBook-Pro")
IO.puts('Starting Paxos')

pid1 = Paxos.start(a, [a, b, c], self())

pid2 = Paxos.start(b, [a, b, c], self())

pid3 = Paxos.start(c, [a, b, c], self())

IO.puts('Getting State')
Paxos.propose(pid1, 100)
Paxos.start_ballot(pid1)
Paxos.propose(pid2, 200)
Paxos.start_ballot(pid2)
Paxos.propose(pid3, 300)
Paxos.start_ballot(pid3)
Process.sleep(20)
Paxos.gets(pid1)
Paxos.gets(pid2)
Paxos.gets(pid3)
