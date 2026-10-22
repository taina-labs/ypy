defmodule Mix.Tasks.Ypy.Install do
  @shortdoc "Copia as migracoes do kernel Ypy para o produto"

  @moduledoc """
  Copia as migracoes do kernel para o repositorio do produto.

  Cada arquivo de `priv/ypy/migrations` do Ypy vai para o diretorio de
  migracoes do produto, `priv/repo/migrations` por padrao, com a versao
  preservada. O caminho e trocavel com `--migrations-path`.

  Rodar de novo nao duplica: uma versao que ja existe e sobrescrita no
  lugar, e o terminal avisa quando o conteudo era outro. Depois da copia,
  as migracoes sao do produto: quem roda e o `ecto.migrate` dele.

  ## Uso

      mix ypy.install
      mix ypy.install --migrations-path priv/meu_repo/migrations
  """

  use Mix.Task

  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    {opts, _args} =
      OptionParser.parse!(args,
        strict: [migrations_path: :string],
        aliases: [m: :migrations_path]
      )

    origem = Application.app_dir(:ypy, "priv/ypy/migrations")
    destino = Keyword.get(opts, :migrations_path, "priv/repo/migrations")
    File.mkdir_p!(destino)

    origem
    |> arquivos()
    |> Enum.each(&copiar(&1, destino))
  end

  defp arquivos(origem), do: origem |> Path.join("*.exs") |> Path.wildcard() |> Enum.sort()

  defp copiar(arquivo, destino) do
    nome = Path.basename(arquivo)
    conteudo = File.read!(arquivo)
    versao = versao(nome)

    case Path.wildcard(Path.join(destino, versao <> "_*.exs")) do
      [] -> criar(Path.join(destino, nome), conteudo)
      existentes -> Enum.each(existentes, &atualizar(&1, conteudo, versao))
    end
  end

  defp criar(caminho, conteudo) do
    File.write!(caminho, conteudo)
    Mix.shell().info("* criando #{caminho}")
  end

  defp atualizar(caminho, conteudo, versao) do
    if File.read!(caminho) != conteudo do
      File.write!(caminho, conteudo)

      Mix.shell().info("* atualizando #{caminho} (a versao #{versao} ja existia com outro conteudo)")
    end
  end

  defp versao(nome), do: nome |> String.split("_", parts: 2) |> hd()
end
