defmodule Ypy.BlobStore.Disk do
  @moduledoc """
  Blobs em disco, arborizados pelo proprio CID (RFC_006 secao 4):

      <root>/ab/cd/b<base32-do-cid>

  Os dois primeiros bytes do digest formam os dois niveis do galho, de modo
  que nenhum diretorio fique grande demais para o filesystem. `put/2` e
  idempotente: os mesmos bytes caem sempre no mesmo CID e no mesmo caminho.
  """

  @behaviour Ypy.BlobStore

  alias Ypy.Cid

  @enforce_keys [:root]
  defstruct [:root]

  @type t :: %__MODULE__{root: Path.t()}

  @doc "Um Disk enraizado em `root` (tipicamente `Ypy.Layout.blobs`)."
  @spec new(Path.t()) :: t()
  def new(root) when is_binary(root), do: %__MODULE__{root: root}

  @impl true
  def put(store, data) when is_binary(data) do
    cid = Cid.from_data(data, Cid.raw())
    path = path(store, cid)

    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(path, data) do
      {:ok, cid}
    end
  end

  @impl true
  def fetch(store, cid) do
    case File.read(path(store, cid)) do
      {:ok, data} -> {:ok, data}
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def stat(store, cid) do
    case File.stat(path(store, cid)) do
      {:ok, %{size: size}} when size > 0 -> {:ok, %{size: size}}
      {:ok, _} -> {:error, :not_found}
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def open(store, cid) do
    path = path(store, cid)

    if File.exists?(path),
      do: {:ok, path},
      else: {:error, :not_found}
  end

  @impl true
  def delete(store, cid) do
    case File.rm(path(store, cid)) do
      :ok -> :ok
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp path(%__MODULE__{} = store, %Cid{} = cid) do
    <<a, b, _rest::binary>> = cid.digest
    Path.join([store.root, shard(a), shard(b), Cid.to_string(cid)])
  end

  defp shard(byte), do: byte |> Integer.to_string(16) |> String.pad_leading(2, "0")
end
