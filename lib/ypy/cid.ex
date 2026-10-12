defmodule Ypy.Cid do
  @moduledoc "CIDv1: version, codec, and a sha2-256 multihash."

  alias Ypy.Base32
  alias Ypy.Varint

  @sha2_256 0x12
  @dag_cbor 0x71
  @raw 0x55

  defstruct version: 1, codec: @dag_cbor, hash_algo: @sha2_256, digest: nil

  @doc "Codec for content-addressed raw bytes."
  def raw, do: @raw

  @doc "Multihash code for sha2-256."
  def sha2_256, do: @sha2_256

  @doc "Builds a CIDv1 for `data` under the given codec (default dag-cbor)."
  def from_data(data, codec \\ @dag_cbor) do
    %__MODULE__{codec: codec, digest: :crypto.hash(:sha256, data)}
  end

  @doc "Serializes to version, codec, multihash bytes."
  def to_bytes(%__MODULE__{} = cid) do
    Varint.encode(cid.version) <>
      Varint.encode(cid.codec) <>
      Varint.encode(cid.hash_algo) <>
      Varint.encode(byte_size(cid.digest)) <>
      cid.digest
  end

  @doc "Renders the multibase string form: a b prefix over lowercase base32."
  def to_string(cid), do: "b" <> Base32.encode(to_bytes(cid))

  @doc "Parses a base32-multibase CID string. Raises on malformed input."
  def parse("b" <> rest), do: rest |> Base32.decode!() |> from_bytes()
  def parse(_), do: raise(ArgumentError, "not a multibase base32 CID")

  @doc """
  Parses a CID string, or answers :error.

  Raising is right for a CID the kernel itself computed and wrong for one
  untrusted input supplied: the raise happens inside whoever handles the
  input, so a malformed string takes that handling down with it. Every path
  that reads a CID from the wire goes through here, not through parse/1.
  """
  def safe_parse(cid) do
    {:ok, parse(cid)}
  rescue
    ArgumentError -> :error
  end

  @doc "Parses the binary form. Raises ArgumentError on a version other than 1 or a malformed tail."
  def from_bytes(bin) do
    {version, rest} = Varint.decode(bin)

    if version != 1 do
      raise ArgumentError, "unsupported CID version: #{version}"
    end

    {codec, rest} = Varint.decode(rest)
    {algo, rest} = Varint.decode(rest)
    {len, rest} = Varint.decode(rest)

    case rest do
      <<digest::binary-size(^len)>> ->
        %__MODULE__{codec: codec, hash_algo: algo, digest: digest}

      _ ->
        raise ArgumentError, "malformed CID bytes: truncated digest or trailing garbage"
    end
  end
end
