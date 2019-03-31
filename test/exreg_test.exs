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
      assert [^pid] = :pg2.get_members({:"$exreg", name})
    end

    test "registers a name if the group already exists", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, spawn(fn -> :ok end))
      assert [] = :pg2.get_members({:"$exreg", name})
      assert :yes = ExReg.register_name(name, pid)
      assert [^pid] = :pg2.get_members({:"$exreg", name})
    end

    test "does not register the same name twice", %{name: name} do
      pid = self()

      assert :yes = ExReg.register_name(name, pid)
      assert :yes = ExReg.register_name(name, pid)
      assert [^pid] = :pg2.get_members({:"$exreg", name})
    end

    test "avoids naming two processes the same", %{name: name} do
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
      assert {:error, _} = :pg2.get_members({:"$exreg", name})
    end

    test "unregisters name when is empty", %{name: name} do
      assert :yes = ExReg.register_name(name, spawn(fn -> :ok end))
      assert [] = :pg2.get_members({:"$exreg", name})
      assert :ok = ExReg.unregister_name(name)
      assert {:error, _} = :pg2.get_members({:"$exreg", name})
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
      assert ^pid = ExReg.send({:local, name}, "bar")
      assert_receive "bar"
    end
  end

  describe "via tuples" do
    defmodule Counter do
      use Agent

      def start_link(options \\ []) do
        Agent.start_link(fn -> 0 end, options)
      end

      def stop(counter) do
        Agent.stop(counter)
      end

      def increment(counter) do
        Agent.get_and_update(counter, &{&1 + 1, &1 + 1})
      end
    end

    test "registers name", %{name: name} do
      assert {:ok, pid} = Counter.start_link(name: ExReg.local(name))
      assert [^pid] = :pg2.get_members({:"$exreg", name})
    end

    test "sends message to name", %{name: name} do
      assert {:ok, pid} = Counter.start_link(name: ExReg.local(name))
      assert 1 = Counter.increment(ExReg.global(name))
    end
  end
end
