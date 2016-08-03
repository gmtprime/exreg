defmodule ExReg.Mixfile do
  use Mix.Project

  @version "0.0.2"

  def project do
    [app: :exreg,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     docs: docs(),
     deps: deps()]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:earmark, ">= 0.0.0", only: :dev},
     {:ex_doc, "~> 0.12", only: :dev},
     {:credo, "~> 0.4", only: [:dev, :docs]},
     {:inch_ex, ">= 0.0.0", only: [:dev, :docs]}]
  end

  defp docs do
    [source_url: "https://github.com/gmtprime/exreg",
     source_ref: "v#{@version}",
     main: ExReg]
  end

  defp description do
    """
    A simple process name registry using pg2.
    """
  end

  defp package do
    [maintainers: ["Alexander de Sousa"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/gmtprime/exreg"}]
  end
end
