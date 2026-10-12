defmodule Ypy.RacyRepo do
  @moduledoc """
  O repo que simula o escritor concorrente do mural (RFC_006 secao 8): o
  teste arma um `Ypy.Mural.Store.append` verdadeiro (com `Ypy.TestRepo` e os
  keys dados) e a proxima insercao do store sob teste encontra a sequencia
  tomada, conflita no indice unico e precisa recomecar da cabeca.

  Deterministico: nada de sono nem corrida de relogio. `arm/4` conflita uma
  vez e `arm_always/4` conflita em toda insercao (para esgotar as tres
  tentativas e ver {:error, :chain_conflict}).
  """

  @armed :racy_repo_armed

  def arm(keys, tekoa_id, tipo, payload) do
    Process.put(@armed, {:once, keys, tekoa_id, tipo, payload})
  end

  def arm_always(keys, tekoa_id, tipo, payload) do
    Process.put(@armed, {:always, keys, tekoa_id, tipo, payload})
  end

  def disarm, do: Process.delete(@armed)

  def one(query, opts \\ []), do: Ypy.TestRepo.one(query, opts)
  def all(query, opts \\ []), do: Ypy.TestRepo.all(query, opts)

  def insert(changeset, opts \\ []) do
    case Process.get(@armed) do
      nil ->
        Ypy.TestRepo.insert(changeset, opts)

      {mode, keys, tekoa_id, tipo, payload} ->
        if mode == :once, do: disarm()
        _ = Ypy.Mural.Store.append(Ypy.TestRepo, keys, tekoa_id, tipo, payload)
        Ypy.TestRepo.insert(changeset, opts)
    end
  end

  def update(changeset, opts \\ []), do: Ypy.TestRepo.update(changeset, opts)
  def transaction(fun, opts \\ []), do: Ypy.TestRepo.transaction(fun, opts)
  def update_all(query, updates), do: Ypy.TestRepo.update_all(query, updates)

  def aggregate(query, aggregate, field \\ nil, opts \\ []) do
    Ypy.TestRepo.aggregate(query, aggregate, field, opts)
  end

  def reload(struct, opts \\ []), do: Ypy.TestRepo.reload(struct, opts)
end
