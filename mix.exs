defmodule Ypy.MixProject do
  use Mix.Project

  # Ypy is the Taina kernel: a library, not an application. It ships the pure
  # protocol shapes, the social core and the schema layer that products (the
  # Taina box, the hosted platform, future products) build on. It has no
  # endpoint, no config layer and no release: those belong to the product.
  def project do
    [
      app: :ypy,
      version: "0.0.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto, :public_key]]
  end

  def cli do
    [preferred_envs: [precommit: :test]]
  end

  # Dependencies are decisions, not defaults (RFC 006). Ecto stands under the
  # schema layer and bcrypt under credentials; both are runtime. The SQLite
  # driver, stream_data and ex_doc never reach :prod.
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
