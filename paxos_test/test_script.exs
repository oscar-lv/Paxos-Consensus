:os.cmd('/bin/rm -f *.beam')
IEx.Helpers.c "Paxos.ex"
IEx.Helpers.c "test_harness.ex"
IEx.Helpers.c "paxos_test.ex"

# Replace with your own implementation source files

# ##########


# Different configurations to run tests with
config_3_local = %{
        p1: {:local, 101},
        p2: {:local, 102},
        p3: {:local, 103}
}

config_5_local = %{
        p1: {:local, 101},
        p2: {:local, 102},
        p3: {:local, 103},
        p4: {:local, 104},
        p5: {:local, 105}
}

# Replace the following with the short host name of your machine
host = "CS-STF-00373"
# ###########

get_node = fn node -> String.to_atom(node <> "@" <> host) end

config_3_dist = %{
        p1: {get_node.("alice"), {:val, 101}},
        p2: {get_node.("bob"), {:val, 102}},
        p3: {get_node.("charlie"), {:val, 103}},
}

config_5_dist = %{
        p1: {get_node.("alice"), {:val, 101}},
        p2: {get_node.("boris"), {:val, 102}},
        p3: {get_node.("charlie"), {:val, 103}},
        p4: {get_node.("donald"), {:val, 104}},
        p5: {get_node.("eve"), {:val, 105}},
}

test_suite = [
#   test case, configuration, number of times to run the case, description
    {&PaxosTest.run_simple/3, config_3_local, 1, "No failures, no concurrent ballots"},
    {&PaxosTest.run_simple_2/3, config_3_dist, 1, "No failures, 2 concurrent ballots"},
    {&PaxosTest.run_simple_many/3, config_5_dist, 1, "No failures, many concurrent ballots"},
    {&PaxosTest.run_non_leader_crash/3, config_3_local, 1, "One non-leader crashes, no concurrent ballots"},
    {&PaxosTest.run_minority_non_leader_crash/3, config_5_dist, 1, "Minority non-leader crashes, no concurrent ballots"},
    {&PaxosTest.run_leader_crash_simple/3, config_5_dist, 1, "Leader crashes, no concurrent ballots"}
]

if Node.self == get_node.("coord") do
    Enum.reduce(test_suite, length(test_suite),
        fn ({func, config, n, doc}, acc) ->
            IO.puts("============")
            IO.puts("#{inspect doc}, #{inspect n} time#{if n > 1, do: "s", else: ""}")
            IO.puts("============")
            for _ <- 1..n, do: TestHarness.test(func, Enum.shuffle(Map.to_list(config)))
            IO.puts("============#{if acc > 1, do: "\n", else: ""}")
            acc - 1 end)
    System.halt
end
