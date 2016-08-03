defmodule ExReg do
  @moduledoc """
  A simple process name registry using `:pg2`. Uses `:pg2` (running by default
  when starting the EVM) to associate a name (any Elixir term) to a process.

  ## Example

  A simple ping-pong server:

      defmodule Server do
        use GenServer

        def start_link(opts \\ []) do
          GenServer.start_link(__MODULE__, nil, opts)
        end

        def stop(name, reason \\ :normal) do
          GenServer.stop(name, reason)
        end

        def ping(name) do
          GenServer.call(name, :ping)
        end

        def handle_call(:ping, _from, _) do
          {:reply, :pong, nil}
        end
      end

  And using `ExReg` as name registry:

      iex(1)> name = {:name, make_ref()}
      iex(2)> {:ok, pid} = Server.start_link({:via, ExReg, name})
      iex(3)> Server.ping({:via, ExReg, name})
      :pong
      iex(4)> Server.stop({:via, ExReg, name})
      :ok
  """

  ##
  # Gets the real process name.
  defp get_real_name(name), do: {:"$exreg", name}

  @doc """
  Registers the process `pid` with the term `name`.
  """
  @spec register_name(name :: term, pid :: pid) :: :yes | :no
  def register_name(name, pid) do
    real_name = get_real_name(name)
    :pg2.create(real_name)
    case :pg2.get_members(real_name) do
      {:error, {:no_such_group, ^real_name}} ->
        :pg2.join(real_name, pid)
        :yes
      [] ->
        :pg2.join(real_name, pid)
        :yes
      [^pid] ->
        :yes
      _ ->
        :no
    end
  end

  @doc """
  Unregisters a `name`.
  """
  @spec unregister_name(name :: term) :: term
  def unregister_name(name) do
    real_name = get_real_name(name)
    :pg2.delete(real_name)
  end

  @doc """
  Searches for the PID associated with the `name`.
  """
  @spec whereis_name(name :: term) :: pid | :undefined
  def whereis_name(name) do
    real_name = get_real_name(name)
    case :pg2.get_members(real_name) do
      {:error, _} -> :undefined
      [] -> :undefined
      [pid | _] -> pid
    end
  end

  @doc """
  Sends a `message` to the PID associated with `name`.
  """
  @spec send(name :: term, message :: term) :: pid
  def send(name, message) do
    case whereis_name(name) do
      :undefined ->
        exit({:badarg, {name, message}})
      pid ->
        Kernel.send(pid, message)
        pid
    end
  end
end
