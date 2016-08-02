defmodule ExRegTest do
  use ExUnit.Case, async: true

  defmodule TestServer do
    use GenServer

    defp via_tuple(name) do
      {:via, ExReg, name}
    end

    def start_link(name) do
      GenServer.start_link(__MODULE__, nil, [name: via_tuple(name)])
    end

    def stop(name) do
      GenServer.stop(via_tuple(name))
    end

    def ping(name) do
      GenServer.call(via_tuple(name), :ping)
    end

    def handle_call(:ping, _from, _) do
      {:reply, {:pong, self()}, nil}
    end
  end

  test "register_name/2 - unregister_name/1" do
    ref = make_ref()
    name = {:name, ref}
    real_name = {:"$exreg", name}
    pid = self()
    assert :yes = ExReg.register_name(name, pid)
    assert [^pid] = :pg2.get_members(real_name)
    ExReg.unregister_name(name)
    assert {:error, {:no_such_group, ^real_name}} = :pg2.get_members(real_name)
  end

  test "register_name/2 twice" do
    ref = make_ref()
    name = {:name, ref}
    real_name = {:"$exreg", name}
    pid = self()
    assert :yes = ExReg.register_name(name, pid)
    assert :yes = ExReg.register_name(name, pid)
    assert [^pid] = :pg2.get_members(real_name)
    ExReg.unregister_name(name)
    assert {:error, {:no_such_group, ^real_name}} = :pg2.get_members(real_name)
  end

  test "register_name/2 two processes" do
    ref = make_ref()
    name = {:name, ref}
    real_name = {:"$exreg", name}
    pid = self()
    other = spawn(fn -> :ok end)
    assert :yes = ExReg.register_name(name, pid)
    assert :no = ExReg.register_name(name, other)
    assert [^pid] = :pg2.get_members(real_name)
    ExReg.unregister_name(name)
    assert {:error, {:no_such_group, ^real_name}} = :pg2.get_members(real_name)
  end

  test "whereis_name/1" do
    ref = make_ref()
    name = {:name, ref}
    pid = self()
    assert :yes = ExReg.register_name(name, pid)
    assert ^pid = ExReg.whereis_name(name)
    ExReg.unregister_name(name)
    assert :undefined = ExReg.whereis_name(name)
  end

  test "send/2" do
    ref = make_ref()
    name = {:name, ref}
    pid = self()
    assert :yes = ExReg.register_name(name, pid)
    assert ^pid = ExReg.send(name, :message)
    assert_receive :message
    ExReg.unregister_name(name)
  end

  test "GenServer test" do
    ref = make_ref()
    name = {:name, ref}
    {:ok, client} = TestServer.start_link(name)
    assert {:pong, ^client} = TestServer.ping(name)
    TestServer.stop(name)
  end
end
