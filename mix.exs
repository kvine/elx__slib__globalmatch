defmodule ElxSlibGlobalmatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :elx__slib__globalmatch,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:elx__slib,git: "git@192.168.1.100:XuSheng/elx__slib.git", branch: "strip_globalmatch"}
    ]
  end
end
