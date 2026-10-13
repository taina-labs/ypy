defmodule Ypy.MixProject do
  use Mix.Project

  def project do
    [
      app: :ypy,
      version: "0.1.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      name: "Ypy",
      description: description(),
      source_url: "https://github.com/taina-labs/ypy",
      homepage_url: "https://github.com/taina-labs/ypy",
      package: package()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: [:logger, :crypto, :public_key]]
  end

  def cli do
    [preferred_envs: [precommit: :test]]
  end

  defp description do
    "O kernel do ecossistema Taina: o schema e o nucleo puro compartilhados pelos produtos."
  end

  defp package do
    [
      name: "ypy",
      licenses: ["MPL-2.0"],
      links: %{"GitHub" => "https://github.com/taina-labs/ypy"},
      files: ~w(lib priv api mix.exs README.md LICENSE)
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.14"},
      {:ecto_sql, "~> 3.14"},
      {:bcrypt_elixir, "~> 3.3"},
      {:ecto_sqlite3, "~> 0.25", only: [:dev, :test]},
      {:stream_data, "~> 1.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.40.4", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      precommit: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "test"
      ]
    ]
  end
end
