IEx.Helpers.c("paxos.ex")

pid1 = Paxos.start(:p1, [:p1, :p2, :p3], self())
pid2 = Paxos.start(:p2, [:p1, :p2, :p3], self())
pid3 = Paxos.start(:p3, [:p1, :p2, :p3], self())
Paxos.propose(pid1, 90)
Paxos.start_ballot(pid1)
Process.sleep(20)
Paxos.gets(pid1)
Paxos.gets(pid2)
Paxos.gets(pid3)

a = [1, 2, 3]
el = 2
rank = 0

rank =
  Enum.each(0..(Enum.count(a) - 1), fn x ->
    rank = if(Enum.at(a, x) == el, do: x)
    IO.puts(rank)
  end rank)

for e <- a do
  e if()
end
rank
