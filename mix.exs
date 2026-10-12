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

  # Empty on purpose while the design (RFC 006) is open. Every dependency
  # added here is a decision, not a default.
  defp deps, do: []

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
