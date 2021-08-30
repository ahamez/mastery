import Config

config :mastery_persistence,
  ecto_repos: [MasteryPersistence.Repo]

import_config "#{Mix.env()}.exs"
