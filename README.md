# EtsDeque
EtsDeque is an Elixir implementation of a double-ended queue (deque), using
Erlang's ETS library as a backing store.

Using ETS ensures that all functions in the `EtsDeque` module execute in
amortized O(1) time with a minimum of memory allocations, offering bounded
or unbounded operation with high performance and favorable RAM usage.

Using ETS also means that `EtsDeque` is not a purely functional data
structure, and is not suitable for direct concurrent usage in multiple
processes.  Use the `EtsDeque.Server` GenServer if you would like safe
access to an `EtsDeque` from multiple processes.

You can push items onto, pop items from, or peek at items from the head
or tail of the queue.  Additionally, any item can be accessed or replaced
by its index using `at/2` and `replace_at/3`.

`EtsQueue` implements Elixir's
[Access](https://hexdocs.pm/elixir/Access.html) behaviour and
[Enumerable](https://hexdocs.pm/elixir/Enumerable.html) and
[Collectable](https://hexdocs.pm/elixir/Collectable.html) protocols,
so code like `deque[0]` and `Enum.count(deque)` and
`Enum.into([1, 2, 3], EtsDeque.new())` works as it should.

## Example

    iex> deque = EtsDeque.new(3)
    iex> {:ok, deque} = EtsDeque.push_head(deque, :moe)
    iex> {:ok, deque} = EtsDeque.push_tail(deque, :larry)
    iex> {:ok, deque} = EtsDeque.push_tail(deque, :curly)
    iex> :error = EtsDeque.push_head(deque, :shemp)  ## deque is full
    iex> {:ok, :curly, deque} = EtsDeque.pop_tail(deque)
    iex> {:ok, deque} = EtsDeque.push_tail(deque, :shemp)
    iex> Enum.to_list(deque)
    [:moe, :larry, :shemp]

## Installation

```elixir
def deps do
  [
    {:ets_deque, "~> 0.2"}
  ]
end
```

## Authorship and License

Copyright 2020, Pete Gamache.

This software is released under the [MIT License](MIT_LICENSE.md).
