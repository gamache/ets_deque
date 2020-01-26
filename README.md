# EtsDeque

EtsDeque is an implementation of a double-ended queue (deque), using
Erlang's ETS library as a backing store.

You can push items onto, pop items from, or peek at items from the head
or tail of the queue.  Additionally, any item can be accessed or replaced
by its index using `at/2` and `replace_at/3`.

`EtsQueue` implements Elixir's
[Access](https://hexdocs.pm/elixir/Access.html) behaviour and
[Enumerable](https://hexdocs.pm/elixir/Enumerable.html) and
[Collectable](https://hexdocs.pm/elixir/Collectable.html) protocols,
so code like `deque[0]` and `Enum.count(deque)` and
`Enum.into([1, 2, 3], EtsDeque.new())` works as it should.

## Installation

```elixir
def deps do
  [
    {:ets_deque, "~> 0.1.0"}
  ]
end
```

## Authorship and License

Copyright 2020, Pete Gamache.

This software is released under the MIT License.
