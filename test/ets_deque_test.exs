defmodule EtsDequeTest do
  use ExUnit.Case
  doctest EtsDeque
  doctest EtsDeque.Server

  test "push_head and pop_head" do
    deque = EtsDeque.new()
    assert {:ok, deque} = deque |> EtsDeque.push_head(:hello)
    assert {:ok, deque} = deque |> EtsDeque.push_head(:world)
    assert {:ok, :world, deque} = deque |> EtsDeque.pop_head()
    assert {:ok, :hello, deque} = deque |> EtsDeque.pop_head()
  end

  test "push_tail and pop_tail" do
    deque = EtsDeque.new()
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:hello)
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:world)
    assert {:ok, :world, deque} = deque |> EtsDeque.pop_tail()
    assert {:ok, :hello, deque} = deque |> EtsDeque.pop_tail()
  end

  test "push_head and pop_tail" do
    deque = EtsDeque.new()
    assert {:ok, deque} = deque |> EtsDeque.push_head(:hello)
    assert {:ok, deque} = deque |> EtsDeque.push_head(:world)
    assert {:ok, :hello, deque} = deque |> EtsDeque.pop_tail()
    assert {:ok, :world, deque} = deque |> EtsDeque.pop_tail()
  end

  test "finite size" do
    deque = EtsDeque.new(3)
    assert {:ok, deque} = deque |> EtsDeque.push_head(:hello)
    assert {:ok, deque} = deque |> EtsDeque.push_head(:hello)
    assert {:ok, deque} = deque |> EtsDeque.push_head(:hello)
    assert :error = deque |> EtsDeque.push_head(:hello)
    assert {:ok, :hello, deque} = deque |> EtsDeque.pop_tail()
    assert {:ok, deque} = deque |> EtsDeque.push_head(:hello)
  end

  test "push_head and peek_head" do
    deque = EtsDeque.new()
    assert {:ok, deque} = deque |> EtsDeque.push_head(:hello)
    assert {:ok, :hello} = deque |> EtsDeque.peek_head()
    assert {:ok, deque} = deque |> EtsDeque.push_head(:world)
    assert {:ok, :world} = deque |> EtsDeque.peek_head()
  end

  test "push_tail and peek_tail" do
    deque = EtsDeque.new()
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:hello)
    assert {:ok, :hello} = deque |> EtsDeque.peek_tail()
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:world)
    assert {:ok, :world} = deque |> EtsDeque.peek_tail()
  end

  test "Collectable" do
    deque = Enum.into([:hello, :world], EtsDeque.new())
    assert {:ok, :hello, deque} = deque |> EtsDeque.pop_head()
    assert {:ok, :world, deque} = deque |> EtsDeque.pop_head()
  end

  test "Access" do
    deque = EtsDeque.new()
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:hello)
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:world)

    ## fetch
    assert :hello == deque[0]
    assert :world == deque[1]
    assert nil == deque[2]

    ## get_and_update
    assert {:hello, deque} =
             Access.get_and_update(deque, 0, fn x ->
               {x, :goodbye}
             end)

    assert :goodbye == deque[0]
    assert :world == deque[1]

    ## pop
    assert {:world, deque} = Access.pop(deque, 1)
    assert {:goodbye, deque} = Access.pop(deque, 0)
  end

  test "Enumerable" do
    deque = EtsDeque.new()
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:hello)
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:world)
    assert [:hello, :world] = Enum.to_list(deque)

    ## count
    assert 2 == Enum.count(deque)

    ## slice
    assert [:world] == Enum.slice(deque, 1, 1)
    assert [] == Enum.slice(deque, 1, 0)

    ## reduce
    assert "helloworld" ==
             Enum.reduce(deque, "", fn item, acc ->
               "#{acc}#{item}"
             end)
  end

  test "errors" do
    deque = EtsDeque.new(1)
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:hello)
    assert :error = deque |> EtsDeque.push_tail(:hello)
    assert :error = deque |> EtsDeque.push_head(:hello)
    assert {:ok, :hello, deque} = deque |> EtsDeque.pop_head()
    assert :error = deque |> EtsDeque.pop_head()
    assert :error = deque |> EtsDeque.pop_tail()
    assert :error = EtsDeque.at(deque, 22)
    assert :error = EtsDeque.replace_at(deque, 22, 22)
  end

  test "bangs" do
    deque = EtsDeque.new()
    assert deque = deque |> EtsDeque.push_head!(:hello)
    assert deque = deque |> EtsDeque.push_tail!(:world)
    assert :hello = deque |> EtsDeque.at!(0)
    assert deque = deque |> EtsDeque.replace_at!(0, :goodbye)
    assert :world = deque |> EtsDeque.peek_tail!()
    assert {:world, deque} = deque |> EtsDeque.pop_tail!()
    assert :goodbye = deque |> EtsDeque.peek_head!()
    assert {:goodbye, deque} = deque |> EtsDeque.pop_head!()
  end

  test "bang errors" do
    deque = EtsDeque.new(1)
    assert {:ok, deque} = deque |> EtsDeque.push_tail(:hello)
    assert_raise ArgumentError, fn -> deque |> EtsDeque.push_tail!(:hello) end
    assert_raise ArgumentError, fn -> deque |> EtsDeque.push_head!(:hello) end
    assert {:ok, :hello, deque} = deque |> EtsDeque.pop_head()
    assert_raise ArgumentError, fn -> deque |> EtsDeque.peek_head!() end
    assert_raise ArgumentError, fn -> deque |> EtsDeque.peek_tail!() end
    assert_raise ArgumentError, fn -> deque |> EtsDeque.pop_head!() end
    assert_raise ArgumentError, fn -> deque |> EtsDeque.pop_tail!() end
    assert_raise ArgumentError, fn -> EtsDeque.at!(deque, 22) end
    assert_raise ArgumentError, fn -> EtsDeque.replace_at!(deque, 22, 22) end
  end

  test "Server" do
    assert {:ok, pid} = EtsDeque.Server.start_link(size: 2)
    assert :ok = EtsDeque.Server.push_head(pid, :hello)
    assert :ok = EtsDeque.Server.push_tail(pid, :world)
    assert {:ok, :hello} = EtsDeque.Server.peek_head(pid)
    assert {:ok, :world} = EtsDeque.Server.peek_tail(pid)
    assert {:ok, :world} = EtsDeque.Server.at(pid, 1)
    assert :ok = EtsDeque.Server.replace_at(pid, 1, :there)
    assert [:hello, :there] = EtsDeque.Server.execute(pid, &Enum.to_list/1)
    assert {:ok, :hello} = EtsDeque.Server.pop_head(pid)
    assert {:ok, :there} = EtsDeque.Server.pop_tail(pid)
    assert :error = EtsDeque.Server.pop_tail(pid)
    assert 0 == EtsDeque.Server.length(pid)
    assert 2 == EtsDeque.Server.size(pid)
    assert %EtsDeque{length: 0} = EtsDeque.Server.deque(pid)
  end

  test "big deque" do
    deque =
      1..1_000_000
      |> Enum.reduce(EtsDeque.new(), fn i, deque ->
        EtsDeque.push_tail!(deque, i)
      end)

    assert 1_000_000 == EtsDeque.length(deque)
    assert {1, deque} = EtsDeque.pop_head!(deque)
    assert {1_000_000, deque} = EtsDeque.pop_tail!(deque)
  end
end
