IEx.Helpers.c("srs.ex")

pid1 = SRS.start(:p1, [:p1, :p2], self())
pid2 = SRS.start(:p2, [:p1, :p2], self())
SRS.reserve(pid1, 'test1')
