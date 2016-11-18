# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :lodestoner_ex,
  endpoint: "http://na.finalfantasyxiv.com/lodestone",
  rest_client: LodestonerEx.Client.REST

if Mix.env == :test do
  import_config "test.exs"
end

