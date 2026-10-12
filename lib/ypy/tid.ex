defmodule Ypy.Tid do
  @moduledoc """
  Timestamp IDs: 13 chars of base32-sortable encoding
  (timestamp_micros <<< 10 ||| clock_id). Pure: the caller supplies the
  microsecond timestamp and the clock id counter; there is no clock read and
  no process state. Two calls with the same `last` can answer the same value,
  because both were given the same timestamp. Strict increase comes from
  threading the integer the previous call returned back in as `last`, which
  is how the chain writes use it.
  """

  import Bitwise

  @alphabet ~c"234567abcdefghijklmnopqrstuvwxyz"

  @doc """
  Returns {tid_string, integer_value}, strictly greater than `last`.

  `micros` is the microsecond timestamp and `clock_id` the caller's counter
  in the low 10 bits.
  """
  def next(last, micros, clock_id)
      when is_integer(last) and last >= 0 and is_integer(micros) and micros >= 0 and
             is_integer(clock_id) and clock_id >= 0 and clock_id <= 1023 do
    n = max(last + 1, micros <<< 10 ||| clock_id)
    {encode(n), n}
  end

  @doc "Encodes an integer as the 13-char sortable form. The encoding is only defined up to 64 bits."
  def encode(n) when is_integer(n) and n >= 0 do
    for i <- 0..12, into: "" do
      <<Enum.fetch!(@alphabet, n >>> (60 - i * 5) &&& 0x1F)>>
    end
  end
end
