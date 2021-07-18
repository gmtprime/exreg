defmodule ExRegTest do
  use ExUnit.Case, async: true

  setup do
    name = {:foo, make_ref()}

    {:ok, [name: name]}
  end

  describe "local/1" do
    test "returns local via tuple", %{name: name} do
      assert {:via, ExReg, {:local, ^name}} = ExReg.local(name)
    end
  end

  describe "global/1" do
    test "returns global via tuple", %{name: name} do
      assert {:via, ExReg, {:global, ^name}} = ExReg.global(name)
    end
  end

  describe "register_name/2" do
    test "registers a new name", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert [^pid] = :pg.get_members(ExReg, {:"$exreg", name})
    end

    test "doesn't register the same process twice", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert :yes = ExReg.register_name(name, pid)
      assert [^pid] = :pg.get_members(ExReg, {:"$exreg", name})
    end

    test "avoids two processes sharing the same name", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert :no = ExReg.register_name(name, spawn(fn -> :ok end))
    end
  end

  describe "unregister_name/1" do
    test "unregisters an existent name", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert :ok = ExReg.unregister_name(name)
      assert [] = :pg.get_members(ExReg, {:"$exreg", name})
    end

    test "does nothing when the name does not exist", %{name: name} do
      assert :ok = ExReg.unregister_name(name)
    end
  end

  describe "whereis_name/1" do
    test "looks for local processes", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert ^pid = ExReg.whereis_name({:local, name})
    end

    test "looks for global processes", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert ^pid = ExReg.whereis_name({:global, name})
    end

    test "looks for processes by name", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert ^pid = ExReg.whereis_name(name)
    end
  end

  describe "send/2" do
    test "sends messages to local processes", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert ^pid = ExReg.send({:local, name}, "bar")
      assert_receive "bar"
    end

    test "sends messages to global processes", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert ^pid = ExReg.send({:global, name}, "bar")
      assert_receive "bar"
    end

    test "sends messages to processes", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert ^pid = ExReg.send(name, "bar")
      assert_receive "bar"
    end

    test "raises when the process does not exist", %{name: name} do
      assert_raise ArgumentError, fn -> ExReg.send(name, "bar") end
    end
  end

  describe "via tuples" do
    defmodule Echo do
      use GenServer

      def start_link(options \\ []) do
        GenServer.start_link(__MODULE__, nil, options)
      end

      defdelegate stop(echo), to: GenServer, as: :stop
      defdelegate echo(echo, message), to: GenServer, as: :call

      @impl true
      def init(nil), do: {:ok, nil}

      @impl true
      def handle_call(message, {pid, _}, nil) do
        send(pid, message)
        {:reply, :ok, nil}
      end
    end

    test "registers name", %{name: name} do
      assert {:ok, pid} = Echo.start_link(name: ExReg.local(name))
      assert [^pid] = :pg.get_members(ExReg, {:"$exreg", name})
    end

    test "sends message to name", %{name: name} do
      assert {:ok, pid} = Echo.start_link(name: ExReg.local(name))
      assert [^pid] = :pg.get_members(ExReg, {:"$exreg", name})

      message = :message
      assert :ok = Echo.echo(ExReg.global(name), message)
      assert_receive ^message
    end
  end
end
