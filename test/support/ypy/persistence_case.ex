defmodule Ypy.PersistenceCase do
  @moduledoc """
  O casco de teste da camada de persistencia: sandbox de conexao e os
  lexicons do kernel carregados, como o produto carrega no boot.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Ypy.PersistenceCase

      alias Ypy.TestRepo
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Ypy.TestRepo)

    {entries, problems} =
      Ypy.Lexicon.Registry.load([Path.join(File.cwd!(), "priv/lexicons")])

    assert problems == []
    assert map_size(entries) == 2

    :ok
  end
end
