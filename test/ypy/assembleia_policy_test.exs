defmodule Ypy.Assembleia.PolicyTest do
  use ExUnit.Case, async: true

  alias Ypy.Assembleia.Policy

  test "quorum is ceil(moradores/2)" do
    for {moradores, esperado} <- [
          {0, 0},
          {1, 1},
          {2, 1},
          {3, 2},
          {4, 2},
          {5, 3},
          {6, 3},
          {7, 4},
          {8, 4}
        ] do
      assert Policy.quorum(moradores) == esperado
    end
  end

  test "tally passes with quorum and a simple majority" do
    assert Policy.tally([:yes, :yes, :no], 5) == :passed
    assert Policy.tally([:yes, :yes, :no], 4) == :passed
  end

  test "tally rejects a tie and a no majority" do
    assert Policy.tally([:yes, :no], 4) == :rejected
    assert Policy.tally([:yes, :no, :no], 5) == :rejected
    assert Policy.tally([:no, :no], 4) == :rejected
  end

  test "tally expires when the quorum is missed, even with every vote a yes" do
    assert Policy.tally([:yes, :yes], 5) == :expired
    assert Policy.tally([:yes], 7) == :expired
    assert Policy.tally([], 5) == :expired
  end

  test "a choice that is neither yes nor no is not a vote" do
    assert Policy.tally([:yes, :maybe], 2) == :passed
    assert Policy.tally([:maybe], 2) == :expired
  end

  test "expiry passes exactly at the turn of the deadline" do
    fecha = DateTime.from_naive!(~N[2026-06-01 10:00:00], "Etc/UTC")

    refute Policy.expired?(fecha, DateTime.add(fecha, -1))
    refute Policy.expired?(fecha, fecha)
    assert Policy.expired?(fecha, DateTime.add(fecha, 1))
  end
end
