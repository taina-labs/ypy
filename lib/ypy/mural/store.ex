defmodule Ypy.Mural.Store do
  @moduledoc """
  O append da cadeia unica (RFC_006 secao 8): le a cabeca, sela a entrada,
  assina pela `Ypy.KeyStore`, insere. A serializacao e do banco (indice unico
  em `tekoa_id` + `seq`); se outro escritor tomou a sequencia, recomeca da
  cabeca, ate tres tentativas, e ai responde `{:error, :chain_conflict}`.
  Nenhum processo por repo.
  """

  @max_attempts 3

  alias Ypy.{Cbor, Cid, KeyStore, Mural}
  alias Ypy.Mural.{Entry, Queries}

  @doc """
  Anexa `payload` (mapa de chaves de string) como entrada do `tipo` dado e
  devolve a linha inserida. O `tipo` entra no payload assinado e na coluna de
  projecao.
  """
  @spec append(Ecto.Repo.t(), KeyStore.t(), integer(), String.t(), map()) ::
          {:ok, Entry.t()} | {:error, :chain_conflict | term()}
  def append(repo, keys, tekoa_id, tipo, payload)
      when is_binary(tipo) and is_map(payload) and is_integer(tekoa_id) do
    payload = Map.put(payload, "tipo", tipo)
    insert(repo, keys, tekoa_id, tipo, payload, @max_attempts)
  end

  @doc "A cabeca da cadeia (nil no genesis)."
  def head(repo, tekoa_id), do: repo.one(Queries.head(tekoa_id))

  @doc "A cadeia inteira, do genesis em diante."
  def entradas(repo, tekoa_id), do: repo.all(Queries.entradas(tekoa_id))

  @doc "As entradas de um tipo (a projecao do mural)."
  def por_tipo(repo, tekoa_id, tipo), do: repo.all(Queries.por_tipo(tekoa_id, tipo))

  @doc "Insere pelo changeset dado (uso do produto e dos testes)."
  def insert(repo, changeset), do: repo.insert(changeset)

  defp insert(_repo, _keys, _tekoa_id, _tipo, _payload, 0), do: {:error, :chain_conflict}

  defp insert(repo, keys, tekoa_id, tipo, payload, attempts) do
    head = head(repo, tekoa_id)
    seq = if head, do: head.seq + 1, else: 1
    prev = if head, do: Cid.parse(head.cid), else: nil
    body = %{"seq" => seq, "prev" => prev, "payload" => payload}

    case keys.__struct__.sign(keys, tekoa_id, Cbor.encode(body)) do
      {:ok, signature} ->
        entry = %{"seq" => seq, "prev" => prev, "payload" => payload, "signature" => signature}
        cid = Mural.entry_cid(entry)
        changeset = changeset(tekoa_id, seq, prev, tipo, payload, signature, cid)

        case repo.insert(changeset) do
          {:ok, row} ->
            {:ok, row}

          {:error, %Ecto.Changeset{errors: errors}} = error ->
            if conflict?(errors) do
              insert(repo, keys, tekoa_id, tipo, payload, attempts - 1)
            else
              error
            end
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp conflict?(errors) do
    Enum.any?(errors, fn
      {_field, {_message, [constraint: :unique, constraint_name: _]}} -> true
      _ -> false
    end)
  end

  defp changeset(tekoa_id, seq, prev, tipo, payload, signature, cid) do
    Entry.changeset(%Entry{}, %{
      tekoa_id: tekoa_id,
      seq: seq,
      prev: prev && Cid.to_string(prev),
      tipo: tipo,
      payload: payload,
      signature: signature,
      cid: Cid.to_string(cid)
    })
  end
end
