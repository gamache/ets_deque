defmodule EtsDeque.MixProject do
  use Mix.Project

  @version "0.2.0"
  @repo_url "https://github.com/gamache/ets_deque"

  def project do
    [
      app: :ets_deque,
      description: "A high-performance double-ended queue (deque) based on ETS",
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "EtsDeque",
        source_ref: @version,
        source_url: @repo_url,
      ],
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      maintainers: ["pete gamache <pete@gamache.org>"],
      links: %{github: @repo_url},
    ]
  end

  def application do
    [
      extra_applications: [:logger],
    ]
  end

  defp deps do
    [
      {:freedom_formatter, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
    ]
  end
end
