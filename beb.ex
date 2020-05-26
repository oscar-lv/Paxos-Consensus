defmodule FloodingBC do

  def start(name, participants, upper_layer) do
    pid = spawn(FloodingBC, :init, name, participants, upper_layer])
    :global.unregister_name(name)
    case :global.register_name(name, pid) do
      :yes -> pid
      :no  -> :error
    end
  end

  def propose(name, next, neighbours, upper) do
    state = %{
        name: name,
        next: next,
        upper: upper,
        received: MapSet.new(),  # set of {pid, seqno} pairs
        neighbours: neighbours
     }
     run(state)
  end

  def bc_send(bcast, msg) do
    send(bcast, {:input, :bc_send, msg})
  end

  defp run(state) do
    my_pid = self()
    state = receive do
      {:input, :bc_send, msg} ->
        state = %{ state | received: MapSet.put(state.received, {my_pid, state.next}) }
        for p <- state.neighbours do
          case :global.whereis_name(p) do
            :undefined -> :undefined
            pid -> send(pid, {:relay_msg, state.name, state.name, {my_pid, state.next}, msg})
          end
        end
        send(my_pid, {:output, :bc_receive, state.name, msg})
        state = %{ state | next: state.next + 1}
        state

      {:output, :bc_receive, origin, msg} ->
        send(state.upper, {:output, :bc_receive, origin, msg})
        state

      {:relay_msg, sender, origin, message_id, msg} ->
        if not(MapSet.member?(state.received, message_id)) do
          state = %{ state | received: MapSet.put(state.received, message_id) }
          for p <- state.neighbours, p != sender do
            case :global.whereis_name(p) do
              :undefined -> :undefined
              pid -> send(pid, {:relay_msg, state.name, origin, message_id, msg})
            end
          end
          send(my_pid,{:output, :bc_receive, origin, msg})
          state
        else
          state
        end
    end
    run(state)
  end

end
