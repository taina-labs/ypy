defmodule Ypy.Mural.PersistenceTest do
  use Ypy.PersistenceCase, async: false

  alias Ypy.Mural
  alias Ypy.Mural.Store
  alias Ypy.RacyRepo

  import Ypy.Factories

  setup do
    {tekoa, keys} = nova_tekoa(TestRepo)
    %{tekoa: tekoa, keys: keys}
  end

  test "o append encadeia do genesis: prev nil, seq 1, e a assinatura confere", %{
    tekoa: tekoa,
    keys: keys
  } do
    {:ok, entrada} = Store.append(TestRepo, keys, tekoa.id, "publicar", %{"rkey" => "rk1"})

    assert entrada.seq == 1
    assert entrada.prev == nil
    assert entrada.tipo == "publicar"
    assert entrada.payload == %{"tipo" => "publicar", "rkey" => "rk1"}

    assert Mural.verify_entry(tekoa_pub(TestRepo, tekoa.id), to_entry(entrada)) == :ok
  end

  test "a cadeia cresce encadeada e verifica inteira", %{tekoa: tekoa, keys: keys} do
    {:ok, _} = Store.append(TestRepo, keys, tekoa.id, "publicar", %{"rkey" => "rk1"})
    {:ok, _} = Store.append(TestRepo, keys, tekoa.id, "concessao", %{"rkey" => "rk2"})
    {:ok, ultima} = Store.append(TestRepo, keys, tekoa.id, "put", %{"rkey" => "rk3"})

    assert ultima.seq == 3
    assert Mural.verificar_cadeia(TestRepo, tekoa.id) == :ok
  end

  test "conflito de sequencia sob escritor concorrente: o store recomeca da cabeca e vence", %{
    tekoa: tekoa,
    keys: keys
  } do
    {:ok, primeira} = Store.append(TestRepo, keys, tekoa.id, "put", %{"rkey" => "rk1"})

    # O proximo escritor encontra a seq tomada por um append concorrente
    # verdadeiro e precisa recomecar: a cadeia final fica valida.
    RacyRepo.arm(keys, tekoa.id, "concessao", %{"rkey" => "rival"})

    {:ok, entrada} =
      Store.append(RacyRepo, keys, tekoa.id, "publicar", %{"rkey" => "rk2"})

    RacyRepo.disarm()

    assert entrada.seq == 3
    assert entrada.prev != primeira.cid

    assert Mural.verificar_cadeia(TestRepo, tekoa.id) == :ok
    assert Store.head(TestRepo, tekoa.id).seq == 3
  end

  test "conflito em toda tentativa: tres tentativas e :chain_conflict", %{
    tekoa: tekoa,
    keys: keys
  } do
    {:ok, _} = Store.append(TestRepo, keys, tekoa.id, "put", %{"rkey" => "rk1"})

    RacyRepo.arm_always(keys, tekoa.id, "rival", %{"rkey" => "rival"})

    assert Store.append(RacyRepo, keys, tekoa.id, "publicar", %{"rkey" => "rk2"}) ==
             {:error, :chain_conflict}

    RacyRepo.disarm()

    # Cada tentativa deixou uma entrada do rival; a cadeia, porem, fica valida.
    assert Mural.verificar_cadeia(TestRepo, tekoa.id) == :ok
    assert length(Mural.entradas(TestRepo, tekoa.id)) == 4
  end

  test "sem chave para assinar, o append responde o erro do KeyStore", %{tekoa: tekoa} do
    sem_chave = Ypy.KeyStore.Files.new(Ypy.Factories.dir_temporario("keys-vazias"))

    assert Store.append(TestRepo, sem_chave, tekoa.id, "put", %{"rkey" => "rk1"}) ==
             {:error, :not_found}

    assert Mural.entradas(TestRepo, tekoa.id) == []
  end

  test "a projecao filtra por tipo e pagina por cursor de seq", %{tekoa: tekoa, keys: keys} do
    {:ok, e1} = Store.append(TestRepo, keys, tekoa.id, "publicar", %{"rkey" => "rk1"})
    {:ok, _} = Store.append(TestRepo, keys, tekoa.id, "concessao", %{"rkey" => "rk2"})
    {:ok, e3} = Store.append(TestRepo, keys, tekoa.id, "publicar", %{"rkey" => "rk3"})

    publica = Mural.entradas(TestRepo, tekoa.id, tipo: "publicar")
    assert Enum.map(publica, & &1.seq) == [e1.seq, e3.seq]

    do_meio = Mural.entradas(TestRepo, tekoa.id, cursor: e3.seq)
    assert Enum.map(do_meio, & &1.seq) == [e1.seq, 2]

    assert Mural.entrada(TestRepo, tekoa.id, 2).tipo == "concessao"
    assert Mural.entrada(TestRepo, tekoa.id, 9) == nil
  end

  test "verificar_cadeia sem chave ativa responde :not_found", %{tekoa: tekoa, keys: keys} do
    {:ok, _} = Store.append(TestRepo, keys, tekoa.id, "put", %{"rkey" => "rk1"})

    _ =
      Ypy.Maraca.Store.chave_ativa(TestRepo, tekoa.id)
      |> Ypy.Maraca.TekoaKey.retire_changeset(DateTime.utc_now() |> DateTime.truncate(:second))
      |> TestRepo.update!()

    assert Mural.verificar_cadeia(TestRepo, tekoa.id) == {:error, :not_found}
  end

  defp tekoa_pub(repo, tekoa_id) do
    %Ypy.Maraca.TekoaKey{pub: pub} = Ypy.Maraca.Store.chave_ativa(repo, tekoa_id)
    pub
  end

  defp to_entry(%Ypy.Mural.Entry{} = row) do
    %{
      "seq" => row.seq,
      "prev" => row.prev && Ypy.Cid.parse(row.prev),
      "payload" => row.payload,
      "signature" => row.signature
    }
  end
end
