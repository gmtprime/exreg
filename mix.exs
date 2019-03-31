defmodule ExReg.Mixfile do
  use Mix.Project

  @version "0.1.0"
  @root "https://github.com/gmtprime/exreg"

  def project do
    [
      name: "ExReg",
      app: :exreg,
      version: @version,
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      docs: docs(),
      deps: deps()
    ]
  end

  #############
  # Application

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev},
      {:credo, "~> 1.0", only: :dev}
    ]
  end

  #########
  # Package

  defp package do
    [
      description: "A simple process name registry that uses pg2",
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
