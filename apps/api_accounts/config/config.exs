# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

config :ex_aws,
  dynamodb: [
    port: "8000",
    scheme: "http://",
    host: "localhost"
  ],
  json_codec: Jason

config :ex_aws, :hackney_opts,
  recv_timeout: 30_000,
  pool: :ex_aws_pool

config :api_accounts, ApiAccounts.Mailer, adapter: Bamboo.SesAdapter

config :api_accounts, migrate_on_start: false

import_config "#{config_env()}.exs"
