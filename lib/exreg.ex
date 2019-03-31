defmodule ExReg do
  @moduledoc """
  This module defines the API for a simple and distributed process name
  registry, using `:pg2`. The following features are supported:

  - Accepts any term as process names.
  - Works distributedly.
  - Supports registering processes with the same name as long as they are in
    different nodes.

  ```
  iex>pid = self()
  #PID<0.42.0>
  iex> ExReg.register_name(:foo, pid)
  :yes
  iex> ExReg.whereis_name(:foo)
  #PID<0.42.0>
  iex> ExReg.send(:foo, "bar")
  iex> flush()
  "bar"
  :ok
  iex> ExReg.unregister_name(:foo)
  :ok
  iex> ExReg.send(:foo, "hey")
  ** (ArgumentError) Cannot send "hey" to :foo
  ```
  """

  @typedoc """
  Location.
  """
  @type location :: :local | :global

  @typedoc """
  Process name.
  """
  @type process_name :: term() | {location(), term()}

  ############
  # Public API

  @doc """
  Generates a `:via` tuple for a global `name`.
  """
  @spec global(term()) :: {:via, __MODULE__, process_name()}
  def global(name), do: via(name, :global)

  @doc """
  Generates a `:via` tuple for a local `name`.
  """
  @spec local(term()) :: {:via, __MODULE__, process_name()}
  def local(name), do: via(name, :local)

  @doc """
  Registers `name` as an alias for a local `pid` globally.
  """
  @spec register_name(process_name(), pid()) :: :yes | :no
  def register_name(name, pid) do
    case get_local_pid(name) do
      {:error, {:no_such_group, internal_name}} ->
        :pg2.create(internal_name)
        :pg2.join(internal_name, pid)
        :yes

      {:error, {:no_process, internal_name}} ->
        :pg2.join(internal_name, pid)
        :yes

      ^pid ->
        :yes

      _ ->
        :no
    end
  end

  @doc """
  Unregisters a `name`.
  """
  @spec unregister_name(process_name()) :: :ok
  def unregister_name(name) do
    pid = self()
    internal_name = get_internal_name(name)

    case :pg2.get_members(internal_name) do
      [] ->
        :pg2.delete(internal_name)

      [^pid] ->
        :pg2.delete(internal_name)

      _ ->
        :ok
    end
  end

  @doc """
  Searches for the PID associated with the `name`.
  """
  @spec whereis_name(process_name()) :: pid() | :undefined
  def whereis_name(name)

  def whereis_name({:global, _} = name) do
    case get_closest_pid(name) do
      pid when is_pid(pid) -> pid
      _ -> :undefined
    end
  end

  def whereis_name({:local, _} = name) do
    case get_local_pid(name) do
      pid when is_pid(pid) -> pid
      _ -> :undefined
    end
  end

  def whereis_name(name) do
    whereis_name({:global, name})
  end

  @doc """
  Sends a `message` to the PID associated with `name`.
  """
  @spec send(process_name(), term()) :: pid() | no_return()
  def send(name, message) do
    case whereis_name(name) do
      pid when is_pid(pid) ->
        Kernel.send(pid, message)
        pid

      :undefined ->
        raise ArgumentError,
          message: "Cannot send #{inspect(message)} to #{inspect(name)}"
    end
  end

  #########
  # Helpers

  # Generates a `:via` tuple given a valid `name` and, optionally, a `location`
  # (defaults to `:global`).
  @spec via(term(), location()) :: {:via, __MODULE__, process_name()}
  defp via(name, location)

  defp via(name, location) when location in [:local, :global] do
    {:via, __MODULE__, {location, name}}
  end

  # Gets the internal process name.
  @spec get_internal_name(process_name()) :: {:"$exreg", term()}
  defp get_internal_name(name)

  defp get_internal_name({:local, name}) do
    get_internal_name(name)
  end

  defp get_internal_name({:global, name}) do
    get_internal_name(name)
  end

  defp get_internal_name(name) do
    {:"$exreg", name}
  end

  # Gets the closest PID given a process `name`.
  @spec get_closest_pid(process_name()) ::
          pid()
          | {:error, {:no_process, term()}}
          | {:error, {:no_such_group, term()}}
  defp get_closest_pid(name)

  defp get_closest_pid(name) do
    name
    |> get_internal_name()
    |> :pg2.get_closest_pid()
  end

  # Gets the local PID for the given process `name`.
  @spec get_local_pid(process_name()) ::
          pid()
          | {:error, {:no_process, term()}}
          | {:error, {:no_such_group, term()}}
  defp get_local_pid(name)

  defp get_local_pid(name) do
    internal_name = get_internal_name(name)

    case :pg2.get_local_members(internal_name) do
      [pid | _] when is_pid(pid) ->
        pid

      [] ->
        {:error, {:no_process, internal_name}}

      error ->
        error
    end
  end
end
