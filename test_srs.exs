IEx.Helpers.c("paxos.ex")

IEx.Helpers.c("srs.ex")

pid1 = SRS.start(:p1, [:p1, :p2])
pid2 = SRS.start(:p2, [:p1, :p2])
SRS.reserve(pid1, {:seat1, 'Mr.Brown'})
SRS.gets(pid1)
SRS.gets(pid2)
SRS.reserve(pid1, {:seat1, 'Mr.White'})
SRS.gets(pid1)
SRS.gets(pid2)
