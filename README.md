# ExReg

[![Build Status](https://travis-ci.org/gmtprime/exreg.svg?branch=master)](https://travis-ci.org/gmtprime/exreg) [![Hex pm](http://img.shields.io/hexpm/v/exreg.svg?style=flat)](https://hex.pm/packages/exreg) [![hex.pm downloads](https://img.shields.io/hexpm/dt/exreg.svg?style=flat)](https://hex.pm/packages/exreg)

A simple process name registry using `:pg`:

- Depends on the built-in Erlang's `:pg` app
- Can be used with `:via` tuples for naming `GenServers`, `Agents`, etc.
- Accepts any valid erlang term as process names.
- Supports several processses with the same name as long as they are not in the
  same node. Always picks the node closest to the process that called the
  function.

## Small example

Let's say we define the following `Agent` for keeping a counter:

```elixir
defmodule Counter do
  use Agent

  def start_link(options \\ []) do
    Agent.start_link(fn -> 0 end, options)
  end

  def increment(counter) do
    Agent.get_and_update(counter, &{&1, &1 + 1})
  end
end
```

We can now start it using `ExReg` as name registry:

```elixir
iex(1)> name = {:via, ExReg, {"metric", :my_counter}}
iex(2)> Counter.start_link(name: name)
{:ok, #PID<0.42.0>}
iex(3)> Counter.increment(name)
1
iex(4)> Counter.increment(name)
2
```

# Distributed systems

In a distributed environment, there are several things to notice:

- `ExReg` allows several processes to share the same name as long as they are
  not in the same Erlang node.
- When starting processes a process locally or sending messages exclusively
  to a local process:

  * The name should match the type `{:local, term()}` e.g:
    ```
    Counter.start_link({:via, ExReg, {:local, {"metric", :my_counter}}})
    ```
  * The function `ExReg.local({"metric", :my_counter})` can also be used to
    generate the local via tuple.

- When sending messages to a named process, no matter its location:

  * The name should be the term itself or `{:global, term()}` e.g:
    ```
    Counter.increment({:via, ExReg, {"metric", :my_counter}})
    ```
  * The function `ExReg.global({"metric", :my_counter})` can also be used to
    generate the global via tuple.

## Installation

Add `ExReg` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:exreg, "~> 1.0"}]
end
```

> Requires OTP 24 or more.

## Author

Alexander de Sousa

## License

`ExReg` is released under the MIT License. See the LICENSE file for further
details.
