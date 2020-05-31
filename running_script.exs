IEx.Helpers.c("paxos.ex")

IO.puts('Starting Paxos')

pid1 =
  Paxos.start(
    String.to_atom("alice@oscars-MacBook-Pro"),
    [
      String.to_atom("alice@oscars-MacBook-Pro"),
      String.to_atom("bob@oscars-MacBook-Pro"),
      String.to_atom("charlie@oscars-MacBook-Pro")
    ],
    self()
  )

pid2 =
  Paxos.start(
    String.to_atom("bob@oscars-MacBook-Pro"),
    [
      String.to_atom("alice@oscars-MacBook-Pro"),
      String.to_atom("bob@oscars-MacBook-Pro"),
      String.to_atom("charlie@oscars-MacBook-Pro")
    ],
    self()
  )

pid3 =
  Paxos.start(
    String.to_atom("charlie@oscars-MacBook-Pro"),
    [
      String.to_atom("alice@oscars-MacBook-Pro"),
      String.to_atom("bob@oscars-MacBook-Pro"),
      String.to_atom("charlie@oscars-MacBook-Pro")
    ],
    self()
  )

IO.puts('Getting State')
Paxos.propose(pid1, 200)
Paxos.start_ballot(pid1)
Paxos.start_ballot(pid2)
Paxos.start_ballot(pid3)
Process.sleep(20)
Paxos.gets(pid1)
Paxos.gets(pid2)
Paxos.gets(pid3)
