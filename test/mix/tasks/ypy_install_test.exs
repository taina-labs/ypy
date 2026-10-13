defmodule Mix.Tasks.Ypy.InstallTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @migracao "20261012000001_ypy_kernel_tables.exs"

  @tag :tmp_dir
  test "copia as migracoes do kernel com a versao preservada", %{tmp_dir: tmp} do
    capture_io(fn -> Mix.Task.rerun("ypy.install", ["--migrations-path", tmp]) end)

    assert File.ls!(tmp) == [@migracao]
    assert File.read!(Path.join(tmp, @migracao)) == File.read!(Path.join(origem(), @migracao))
  end

  @tag :tmp_dir
  test "rodar de novo nao duplica nem avisa", %{tmp_dir: tmp} do
    capture_io(fn -> Mix.Task.rerun("ypy.install", ["--migrations-path", tmp]) end)

    saida =
      capture_io(fn ->
        Mix.Task.rerun("ypy.install", ["--migrations-path", tmp])
      end)

    assert saida == ""
    assert File.ls!(tmp) == [@migracao]
  end

  @tag :tmp_dir
  test "versao ja existente com outro conteudo e sobrescrita com aviso", %{tmp_dir: tmp} do
    caminho = Path.join(tmp, @migracao)
    File.write!(caminho, "conteudo antigo")

    saida =
      capture_io(fn ->
        Mix.Task.rerun("ypy.install", ["--migrations-path", tmp])
      end)

    assert saida =~ "atualizando #{caminho}"
    assert File.read!(caminho) == File.read!(Path.join(origem(), @migracao))
    assert File.ls!(tmp) == [@migracao]
  end

  @tag :tmp_dir
  test "versao ja existente sob nome diferente e sobrescrita no lugar", %{tmp_dir: tmp} do
    caminho = Path.join(tmp, "20261012000001_com_outro_nome.exs")
    File.write!(caminho, "conteudo antigo")

    capture_io(fn ->
      Mix.Task.rerun("ypy.install", ["--migrations-path", tmp])
    end)

    assert File.read!(caminho) == File.read!(Path.join(origem(), @migracao))
    assert File.ls!(tmp) == ["20261012000001_com_outro_nome.exs"]
  end

  defp origem, do: Application.app_dir(:ypy, "priv/ypy/migrations")
end
