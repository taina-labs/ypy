defmodule Ypy.TestRepo do
  @moduledoc """
  O repo dos testes: SQLite em memoria, um pool de uma conexao, sob o
  sandbox. O kernel nao define Repo nenhum; este mora em test/support e so o
  ExUnit o ve.
  """

  use Ecto.Repo, otp_app: :ypy, adapter: Ecto.Adapters.SQLite3
end
