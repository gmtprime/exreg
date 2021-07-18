defmodule ExReg.Mixfile do
  use Mix.Project

  @version "1.0.0"
  @root "https://github.com/gmtprime/exreg"

  def project do
    [
      app: :exreg,
      name: "ExReg",
      version: @version,
      elixir: "~> 1.12",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      dialyzer: dialyzer(),
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  #############
  # Application

  defp deps do
    [
      {:ex_doc, "~> 0.24", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  def application do
    [
      extra_applications: [],
      mod: {ExReg, []}
    ]
  end

  def dialyzer do
    [ptl_file: {:no_warn, "priv/plts/exreg"}]
  end

  #########
  # Package

  defp description do
    """
    A simple process name registry that uses pg (formerly known as pg2).
    """
  end

  defp package do
    [
      description: description(),
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md"],
      maintainers: ["Alexander de Sousa"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@root}/blob/master/CHANGELOG.md",
        "Github" => @root
      }
    ]
  end

  ###############
  # Documentation

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md"
      ],
      source_url: @root,
      source_ref: "v#{@version}"
    ]
  end
end
