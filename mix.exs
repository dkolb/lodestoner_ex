defmodule LodestonerEx.Mixfile do
  use Mix.Project

  def project do
    [app: :lodestoner_ex,
     version: "0.0.1",
     description: "A webpage scraper for Lodestone, the character " <>
      "information site for Final Fantasy XIV.",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     elixirc_paths: elixirc_paths(Mix.env),
     package: [
       licenses: ["MIT"],
       maintainers: ["David Kolb <david.kolb@krinchan.com>"],
       links: %{"GitHub" => "https://github.com/dkolb/lodestoner_ex"}
    ],

     # Docs
     name: "LodestonerEx",
     source_url: "https://github.com/dkolb/lodestoner_ex",
     homepage_url: "https://github.com/dkolb/lodestoner_ex",
     docs: [main: "LodestonerEx",
     extras: ["README.md"]]
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :floki, :httpoison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:floki, "~> 0.11.0"},
      {:httpoison, "~> 0.9.2"},
      {:ex_doc, "~> 0.14", only: :dev}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/mocks"]
  defp elixirc_paths(:dev),  do: ["lib", "test/mocks"]
  defp elixirc_paths(_),     do: ["lib"]
end
