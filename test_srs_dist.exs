:os.cmd('/bin/rm -f *.beam')
IEx.Helpers.c("srs.ex")

IEx.Helpers.c("paxos.ex")

IEx.Helpers.c("test_harness.ex")
IEx.Helpers.c("srs_test.ex")
IEx.Helpers.c("uuid.ex")

# Replace with your own implementation source files
# ##########

# Replace the following with the short host name of your machine
host = "heron009"
host = "oscars-MacBook-Pro"

IO.puts('Beggining Distributed Testing of SRS Module')
IO.puts("============")
IO.puts('Test Simple')
IO.puts("============")
SRSTest.test_simple(SRSTest.dist_setup(host))
Process.sleep(50)
IO.puts("============")
IO.puts('Test 5 Bookings')
IO.puts("============")
SRSTest.test_simple_5(SRSTest.dist_setup(host))
Process.sleep(50)
IO.puts("============")
IO.puts('Test that a process can not double book')
IO.puts("============")
SRSTest.test_double_booking(SRSTest.dist_setup(host))
Process.sleep(50)
IO.puts("============")
IO.puts('Test that 2 concurrent ballots result in consensus')
IO.puts("============")
SRSTest.test_2_concurrent(SRSTest.dist_setup(host))
Process.sleep(50)
IO.puts("============")
IO.puts('Test that many concurrent ballots result in consensus')
IO.puts("============")
SRSTest.test_many_concurrent(SRSTest.dist_setup(host))
Process.sleep(50)
IO.puts("============")
IO.puts('Test concurrent ballots, cascading failure of a minority participants')
IO.puts("============")
SRSTest.cascading_minority(SRSTest.dist_setup(host))
Process.sleep(500)
IO.puts("============")
IO.puts('Test concurrent ballots, cascading failure of a minority participants, random delays')
IO.puts("============")
SRSTest.cascading_random_delays(SRSTest.dist_setup(host))
Process.sleep(500)
IO.puts("============")

System.halt()
