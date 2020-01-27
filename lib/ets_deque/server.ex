defmodule EtsDeque.Server do
  @moduledoc ~S"""
  EtsDeque.Server is a GenServer wrapper around an EtsDeque.
  It provides safe access to a deque from multiple processes,
  ensuring each operation on the deque is atomic.

  ## Example

      iex> {:ok, pid} = EtsDeque.Server.start_link(size: 3)
      iex> :ok = EtsDeque.Server.push_head(pid, :moe)
      iex> :ok = EtsDeque.Server.push_tail(pid, :larry)
      iex> :ok = EtsDeque.Server.push_tail(pid, :curly)
      iex> :error = EtsDeque.Server.push_tail(pid, :shemp)  ## deque is full
      iex> {:ok, :curly} = EtsDeque.Server.pop_tail(pid)
      iex> :ok = EtsDeque.Server.push_tail(pid, :shemp)
      iex> EtsDeque.Server.execute(pid, fn deque -> Enum.to_list(deque) end)
      [:moe, :larry, :shemp]
  """

  use GenServer

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  @doc false
  def init(args) do
    size = args[:size] || :infinity
    deque = EtsDeque.new(size)
    {:ok, deque}
  end

  @impl true
  @doc false
  def handle_call({:execute, fun}, _from, deque) do
    {:reply, fun.(deque), deque}
  end

  def handle_call(:deque, _from, deque) do
    {:reply, deque, deque}
  end

  def handle_call({cmd, args}, _from, deque) do
    case :erlang.apply(EtsDeque, cmd, [deque | args]) do
      {:ok, item, %EtsDeque{} = deque} -> {:reply, {:ok, item}, deque}
      {:ok, %EtsDeque{} = deque} -> {:reply, :ok, deque}
      {:ok, item} -> {:reply, {:ok, item}, deque}
      other -> {:reply, other, deque}
    end
  end

  @doc ~S"""
  Adds an item onto the head of the queue. Returns the updated deque,
  or `:error` if the queue is full.
  """
  @spec push_head(pid, any, timeout) :: :ok | :error
  def push_head(pid, item, timeout \\ 5000) do
    GenServer.call(pid, {:push_head, [item]}, timeout)
  end

  @doc ~S"""
  Adds an item onto the tail of the queue. Returns the updated deque,
  or `:error` if the queue is full.
  """
  @spec push_tail(pid, any, timeout) :: :ok | :error
  def push_tail(pid, item, timeout \\ 5000) do
    GenServer.call(pid, {:push_tail, [item]}, timeout)
  end

  @doc ~S"""
  Removes the item at the head of the queue, returning it along with the
  updated deque.
  Returns `:error` if queue is empty.
  """
  @spec pop_head(pid, timeout) :: {:ok, any} | :error
  def pop_head(pid, timeout \\ 5000) do
    GenServer.call(pid, {:pop_head, []}, timeout)
  end

  @doc ~S"""
  Removes the item at the tail of the queue, returning it along with the
  updated deque.
  Returns `:error` if queue is empty.
  """
  @spec pop_tail(pid, timeout) :: {:ok, any} | :error
  def pop_tail(pid, timeout \\ 5000) do
    GenServer.call(pid, {:pop_tail, []}, timeout)
  end

  @doc ~S"""
  Returns the item at the head of the queue, or `:error` if the queue
  is empty.
  """
  @spec peek_head(pid, timeout) :: {:ok, any} | :error
  def peek_head(pid, timeout \\ 5000) do
    GenServer.call(pid, {:peek_head, []}, timeout)
  end

  @doc ~S"""
  Returns the item at the tail of the queue, or `:error` if the queue
  is empty.
  """
  @spec peek_tail(pid, timeout) :: {:ok, any} | :error
  def peek_tail(pid, timeout \\ 5000) do
    GenServer.call(pid, {:peek_tail, []}, timeout)
  end

  @doc ~S"""
  Returns the item at the given index, where index `0` is the head.
  Returns `:error` if index is out of bounds.
  """
  @spec at(pid, non_neg_integer, timeout) :: {:ok, any} | :error
  def at(pid, index, timeout \\ 5000) do
    GenServer.call(pid, {:at, [index]}, timeout)
  end

  @doc ~S"""
  Replaces the item at the given index, returning the updated deque.
  Returns `:error` if index is out of bounds.
  """
  @spec replace_at(pid, non_neg_integer, any, timeout) :: :ok | :error
  def replace_at(pid, index, item, timeout \\ 5000) do
    GenServer.call(pid, {:replace_at, [index, item]}, timeout)
  end

  @doc ~S"""
  Returns the maximum capacity of the given deque.
  """
  @spec size(pid, timeout) :: non_neg_integer | :infinity
  def size(pid, timeout \\ 5000) do
    GenServer.call(pid, {:size, []}, timeout)
  end

  @doc ~S"""
  Returns the number of items in the given deque.
  """
  @spec length(pid, timeout) :: non_neg_integer
  def length(pid, timeout \\ 5000) do
    GenServer.call(pid, {:length, []}, timeout)
  end

  @doc ~S"""
  Executes `fun.(deque)`, ensuring no other process is accessing the
  deque at the same time. Returns the result.
  """
  @spec execute(pid, (EtsDeque.t() -> any), timeout) :: any
  def execute(pid, fun, timeout \\ 5000) do
    GenServer.call(pid, {:execute, fun}, timeout)
  end

  @doc ~S"""
  Returns the deque. Ensuring that no other process mutates
  the deque after it is returned is the caller's responsibility.
  See `execute/3` for a safer alternative.
  """
  @spec deque(pid, timeout) :: EtsDeque.t()
  def deque(pid, timeout \\ 5000) do
    GenServer.call(pid, :deque, timeout)
  end
end
