use Mix.Config

IO.puts("TEST CONFIG LOADED")

config :lodestoner_ex,
  rest_client: LodestonerEx.Client.MOCKREST
