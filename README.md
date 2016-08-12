# ExReg

[![Build Status](https://travis-ci.org/gmtprime/exreg.svg?branch=master)](https://travis-ci.org/gmtprime/exreg) [![Hex pm](http://img.shields.io/hexpm/v/exreg.svg?style=flat)](https://hex.pm/packages/exreg) [![hex.pm downloads](https://img.shields.io/hexpm/dt/exreg.svg?style=flat)](https://hex.pm/packages/exreg) [![Deps Status](https://beta.hexfaktor.org/badge/all/github/gmtprime/exreg.svg)](https://beta.hexfaktor.org/github/gmtprime/exreg) [![Inline docs](http://inch-ci.org/github/gmtprime/exreg.svg?branch=master)](http://inch-ci.org/github/gmtprime/exreg)

A simple process name registry using `:pg2`. Uses `:pg2` (running by default
when starting the EVM) to associate a name (any Elixir term) to a process.

## Example

Defining a simple ping-pong server:

```elixir
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
```

And using `ExReg` as name registry:

```elixir
iex(1)> name = {:name, make_ref()}
iex(2)> Server.start_link(name: {:via, ExReg, name})
iex(3)> Server.ping({:via, ExReg, name})
:pong
iex(4)> Server.stop({:via, ExReg, name})
:ok
```

## Installation

Add `ExReg` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:exreg, "~> 0.0.3"}]
end
```

## Author

Alexander de Sousa

## License

`ExReg` is released under the MIT License. See the LICENSE file for further
details.
