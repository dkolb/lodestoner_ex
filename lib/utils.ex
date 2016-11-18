defmodule LodestonerEx.Utils do
  @rest Application.get_env(:lodestoner_ex, :rest_client)
  alias LodestonerEx.Client.ClientError

  def parse_strfrtime_script(text) do
    Regex.run(~r"ldst_strftime\((\d+).*\)", text, [capture: :all_but_first])
    |> List.first
    |> String.to_integer
    |> DateTime.from_unix
  end

  def get_page_or_raise_client_error(path) do
    case @rest.get(path) do
      {:ok, %HTTPoison.Response{body: html, status_code: 200}} -> 
        html
      {:ok, response} ->
        raise ClientError, response: response, path: path
      {:error, error} ->
        raise ClientError, error: error, path: path
    end
  end
end
