defmodule Mix.Tasks.Ypy.InstallTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @migracoes [
    "20261012000001_ypy_kernel_tables.exs",
    "20261022000001_ypy_ybira_files_effective_at.exs"
  ]

  @tag :tmp_dir
  test "copia as migracoes do kernel com a versao preservada", %{tmp_dir: tmp} do
    capture_io(fn -> Mix.Task.rerun("ypy.install", ["--migrations-path", tmp]) end)

    assert Enum.sort(File.ls!(tmp)) == @migracoes

    for migracao <- @migracoes do
      assert File.read!(Path.join(tmp, migracao)) == File.read!(Path.join(origem(), migracao))
    end
  end

  @tag :tmp_dir
  test "rodar de novo nao duplica nem avisa", %{tmp_dir: tmp} do
    capture_io(fn -> Mix.Task.rerun("ypy.install", ["--migrations-path", tmp]) end)

    saida =
      capture_io(fn ->
        Mix.Task.rerun("ypy.install", ["--migrations-path", tmp])
      end)

    assert saida == ""
    assert Enum.sort(File.ls!(tmp)) == @migracoes
  end

  @tag :tmp_dir
  test "versao ja existente com outro conteudo e sobrescrita com aviso", %{tmp_dir: tmp} do
    caminho = Path.join(tmp, hd(@migracoes))
    File.write!(caminho, "conteudo antigo")

    saida =
      capture_io(fn ->
        Mix.Task.rerun("ypy.install", ["--migrations-path", tmp])
      end)

    assert saida =~ "atualizando #{caminho}"
    assert File.read!(caminho) == File.read!(Path.join(origem(), hd(@migracoes)))
    assert Enum.sort(File.ls!(tmp)) == @migracoes
  end

  @tag :tmp_dir
  test "versao ja existente sob nome diferente e sobrescrita no lugar", %{tmp_dir: tmp} do
    caminho = Path.join(tmp, "20261012000001_com_outro_nome.exs")
    File.write!(caminho, "conteudo antigo")

    capture_io(fn ->
      Mix.Task.rerun("ypy.install", ["--migrations-path", tmp])
    end)

    assert File.read!(caminho) == File.read!(Path.join(origem(), hd(@migracoes)))

    assert Enum.sort(File.ls!(tmp)) == [
             "20261012000001_com_outro_nome.exs",
             Enum.at(@migracoes, 1)
           ]
  end

  defp origem, do: Application.app_dir(:ypy, "priv/ypy/migrations")
end
