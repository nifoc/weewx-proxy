defmodule WeewxProxy.Utils do
  @spec parse_integer(String.t()) :: integer() | nil
  def parse_integer(str) when is_binary(str) and byte_size(str) > 0 do
    case Integer.parse(str) do
      {int, ""} -> int
      _error -> nil
    end
  end

  def parse_integer(_), do: nil

  @spec parse_float(String.t() | integer() | float()) :: float() | nil
  def parse_float(str) when is_binary(str) and byte_size(str) > 0 do
    case Float.parse(str) do
      {float, _rem} -> float
      _error -> nil
    end
  end

  def parse_float(float) when is_float(float), do: float

  def parse_float(int) when is_integer(int), do: int / 1.0

  def parse_float(_), do: nil

  @spec utc_timestamp :: non_neg_integer()
  def utc_timestamp do
    :os.system_time(:seconds)
  end

  @spec utc_offset_string(String.t()) :: String.t()
  def utc_offset_string(tz) do
    {:ok, dt} = DateTime.now(tz)
    offset = dt.utc_offset

    if offset > 0 do
      "+#{offset}"
    else
      to_string(offset)
    end
  end

  @spec append_string(String.t(), String.t()) :: String.t()
  def append_string(str, append) do
    str <> append
  end
end
