import Config

config :mastery_persistence, MasteryPersistence.Repo,
  username: "postgres",
  password: "postgres",
  database: "mastery_dev",
  hostname: "localhost"

config :mastery, :persistence_fn, &MasteryPersistence.record_response/2
