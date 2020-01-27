defmodule EtsDeque do
  @moduledoc """
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
  """

  defstruct [:table, :size, :length, :head]

  @type t :: %__MODULE__{}

  @doc ~S"""
  Creates a deque, optionally limited to a given size.
  """
  @spec new(non_neg_integer | :infinity) :: t()
  def new(size \\ :infinity) do
    table = :ets.new(nil, [:set, :public])
    %__MODULE__{table: table, size: size, length: 0, head: -1}
  end

  @doc ~S"""
  Returns the number of items in the given deque. Equivalent to `deque.length`.
  """
  @spec length(t) :: non_neg_integer
  def length(deque), do: deque.length

  @doc ~S"""
  Returns the maximum capacity of the given deque. Equivalent to `deque.size`.
  """
  @spec size(t) :: non_neg_integer | :infinity
  def size(deque), do: deque.size

  @doc ~S"""
  Adds an item onto the head of the queue. Returns the updated deque,
  or `:error` if the queue is full.
  """
  @spec push_head(t, any) :: {:ok, t} | :error
  def push_head(deque, item) do
    if deque.length + 1 > deque.size do
      :error
    else
      new_head = new_head(deque, 1)
      true = :ets.insert(deque.table, {new_head, item})
      {:ok, %{deque | head: new_head, length: deque.length + 1}}
    end
  end

  @doc ~S"""
  Adds an item onto the head of the queue. Returns the updated deque,
  or raises `ArgumentError` if the queue is full.
  """
  @spec push_head!(t, any) :: t
  def push_head!(deque, item) do
    case push_head(deque, item) do
      {:ok, deque} -> deque
      :error -> raise ArgumentError, "deque is full"
    end
  end

  @doc ~S"""
  Adds an item onto the tail of the queue. Returns the updated deque,
  or `:error` if the queue is full.
  """
  @spec push_tail(t, any) :: {:ok, t} | :error
  def push_tail(deque, item) do
    if deque.length + 1 > deque.size do
      :error
    else
      tail = tail(deque, 1)
      head = if deque.length == 0, do: tail, else: deque.head
      true = :ets.insert(deque.table, {tail, item})
      {:ok, %{deque | length: deque.length + 1, head: head}}
    end
  end

  @doc ~S"""
  Adds an item onto the tail of the queue. Returns the updated deque,
  or raises `ArgumentError` if the queue is full.
  """
  @spec push_tail!(t, any) :: t
  def push_tail!(deque, item) do
    case push_tail(deque, item) do
      {:ok, deque} -> deque
      :error -> raise ArgumentError, "deque is full"
    end
  end

  @doc ~S"""
  Removes the item at the head of the queue, returning it along with the
  updated deque.
  Returns `:error` if queue is empty.
  """
  @spec pop_head(t) :: {:ok, any, t} | :error
  def pop_head(deque) do
    if deque.length == 0 do
      :error
    else
      [{_, item}] = :ets.take(deque.table, deque.head)
      new_head = new_head(deque, -1)
      new_deque = %{deque | length: deque.length - 1, head: new_head}
      {:ok, item, new_deque}
    end
  end

  @doc ~S"""
  Removes the item at the head of the queue, returning it along with the
  updated deque.
  Raises `ArgumentError` if queue is empty.
  """
  @spec pop_head!(t) :: {any, t}
  def pop_head!(deque) do
    case pop_head(deque) do
      {:ok, item, deque} -> {item, deque}
      :error -> raise ArgumentError, "deque is empty"
    end
  end

  @doc ~S"""
  Removes the item at the tail of the queue, returning it along with the
  updated deque.
  Returns `:error` if queue is empty.
  """
  @spec pop_tail(t) :: {:ok, any, t} | :error
  def pop_tail(deque) do
    if deque.length == 0 do
      :error
    else
      tail = tail(deque)
      [{_, item}] = :ets.take(deque.table, tail)
      new_deque = %{deque | length: deque.length - 1}
      {:ok, item, new_deque}
    end
  end

  @doc ~S"""
  Removes the item at the tail of the queue, returning it along with the
  updated deque.
  Raises `ArgumentError` if queue is empty.
  """
  @spec pop_tail!(t) :: {any, t}
  def pop_tail!(deque) do
    case pop_tail(deque) do
      {:ok, item, deque} -> {item, deque}
      :error -> raise ArgumentError, "deque is empty"
    end
  end

  @doc ~S"""
  Returns the item at the head of the queue, or `:error` if the queue
  is empty.
  """
  @spec peek_head(t) :: {:ok, any} | :error
  def peek_head(deque) do
    if deque.length == 0 do
      :error
    else
      [{_, item}] = :ets.lookup(deque.table, deque.head)
      {:ok, item}
    end
  end

  @doc ~S"""
  Returns the item at the head of the queue, or raises `ArgumentError`
  if the queue is empty.
  """
  @spec peek_head!(t) :: any
  def peek_head!(deque) do
    case peek_head(deque) do
      {:ok, item} -> item
      :error -> raise ArgumentError, "deque is empty"
    end
  end

  @doc ~S"""
  Returns the item at the tail of the queue, or `:error` if the queue
  is empty.
  """
  @spec peek_tail(t) :: {:ok, any} | :error
  def peek_tail(deque) do
    if deque.length == 0 do
      :error
    else
      tail = tail(deque)
      [{_, item}] = :ets.lookup(deque.table, tail)
      {:ok, item}
    end
  end

  @doc ~S"""
  Returns the item at the tail of the queue, or raises `ArgumentError`
  if the queue is empty.
  """
  @spec peek_tail!(t) :: any
  def peek_tail!(deque) do
    case peek_tail(deque) do
      {:ok, item} -> item
      :error -> raise ArgumentError, "deque is empty"
    end
  end

  @doc ~S"""
  Returns the item at the given index, where index `0` is the head.
  Returns `:error` if index is out of bounds.
  """
  @spec at(t, non_neg_integer) :: {:ok, any} | :error
  def at(deque, index) do
    if deque.length > index do
      [{_, item}] = :ets.lookup(deque.table, real_index(deque, index))
      {:ok, item}
    else
      :error
    end
  end

  @doc ~S"""
  Returns the item at the given index, where index `0` is the head.
  Raises `ArgumentError` if index is out of bounds.
  """
  @spec at!(t, non_neg_integer) :: any
  def at!(deque, index) do
    case at(deque, index) do
      {:ok, item} -> item
      :error -> raise ArgumentError, "index #{index} out of bounds"
    end
  end

  @doc ~S"""
  Replaces the item at the given index, returning the updated deque.
  Returns `:error` if index is out of bounds.
  """
  @spec replace_at(t, non_neg_integer, any) :: {:ok, t} | :error
  def replace_at(deque, index, item) do
    if deque.length > index do
      true = :ets.insert(deque.table, {real_index(deque, index), item})
      {:ok, deque}
    else
      :error
    end
  end

  @doc ~S"""
  Replaces the item at the given index, returning the updated deque.
  Raises `ArgumentError` if index is out of bounds.
  """
  @spec replace_at!(t, non_neg_integer, any) :: t
  def replace_at!(deque, index, item) do
    case replace_at(deque, index, item) do
      {:ok, deque} -> deque
      :error -> raise ArgumentError, "index #{index} out of bounds"
    end
  end

  @doc false
  @spec new_head(t, integer) :: integer
  def new_head(%{size: :infinity} = deque, increment) do
    deque.head + increment
  end

  def new_head(deque, increment) do
    rem(deque.size + deque.head + increment, deque.size)
  end

  defp tail(deque, decrement \\ 0)

  defp tail(%{size: :infinity} = deque, decrement) do
    deque.head - deque.length + 1 - decrement
  end

  defp tail(deque, decrement) do
    rem(deque.size + deque.head - deque.length + 1 - decrement, deque.size)
  end

  defp real_index(deque, index) do
    if deque.size == :infinity do
      deque.head - index
    else
      rem(deque.size + deque.head - index, deque.size)
    end
  end

  @behaviour Access

  @impl Access
  @doc false
  def fetch(deque, index), do: at(deque, index)

  @impl Access
  @doc false
  def get_and_update(deque, index, fun) do
    case at(deque, index) do
      {:ok, current} ->
        case fun.(current) do
          {get, update} ->
            {:ok, deque} = replace_at(deque, index, update)
            {get, deque}

          :pop ->
            {:ok, item, deque} = deque |> pop_head
            {item, deque}
        end

      _error ->
        raise ArgumentError, "index out of bounds"
    end
  end

  @impl Access
  @doc false
  def pop(deque, index) do
    cond do
      index == 0 ->
        {:ok, item, deque} = deque |> pop_head
        {item, deque}

      index == deque.length - 1 ->
        {:ok, item, deque} = deque |> pop_tail
        {item, deque}

      :else ->
        raise ArgumentError, "removing items not at head or tail is unsupported"
    end
  end
end

defimpl Collectable, for: EtsDeque do
  def into(orig) do
    {orig,
     fn
       deque, {:cont, item} ->
         {:ok, deque} = deque |> EtsDeque.push_tail(item)
         deque

       deque, :done ->
         deque

       _, :halt ->
         :ok
     end}
  end
end

defimpl Enumerable, for: EtsDeque do
  def count(deque), do: {:ok, deque.length}

  def member?(_deque, _item), do: {:error, __MODULE__}

  def reduce(_deque, {:halt, acc}, _fun), do: {:halted, acc}

  def reduce(deque, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(deque, &1, fun)}

  def reduce(%{length: 0}, {:cont, acc}, _fun), do: {:done, acc}

  def reduce(deque, {:cont, acc}, fun) do
    {:ok, head} = deque |> EtsDeque.peek_head()
    new_head = EtsDeque.new_head(deque, -1)
    deque = %{deque | head: new_head, length: deque.length - 1}
    reduce(deque, fun.(head, acc), fun)
  end

  def slice(deque) do
    {:ok, deque.length,
     fn
       _start, 0 ->
         []

       start, len ->
         Enum.reduce((start + len - 1)..start, [], fn index, acc ->
           {:ok, item} = EtsDeque.at(deque, index)
           [item | acc]
         end)
     end}
  end
end
