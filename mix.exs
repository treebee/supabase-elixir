defmodule Supabase.MixProject do
  use Mix.Project

  def project do
    [
      app: :supabase,
      version: "0.2.1",
      description: "A Supabase client for Elixir",
      elixir: "~> 1.11",
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      name: "Supabase",
      source_url: "https://github.com/treebee/supabase-elixir",
      homepage_url: "https://github.com/treebee/supabase-elixir",
      docs: [
        main: "Supabase",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Supabase.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.7.0"},
      {:mime, "~> 1.2"},
      {:tesla, "~> 1.4.1"},
      {:mint, "~> 1.3.0"},
      {:gotrue, "~> 0.2.1"},
      {:postgrestex, "~> 0.1.2"},
      {:excoveralls, "~> 0.13", only: :test},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package() do
    [
      name: "supabase",
      licenses: ["Apache-2.0"],
      links: %{github: "https://github.com/treebee/supabase-elixir"},
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*)
    ]
  end
end
