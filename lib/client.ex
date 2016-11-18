defmodule LodestonerEx.Client do
  @moduledoc false

  defmodule ClientError do
    @moduledoc """
      Indicates an error retrieving content from Lodestone.

      This error is raised when the client has issues retrieving or 
      processing a response.  Often, if the error is HTTP related,
      an HTTPoison.Error or HTTPoison.Response will be included.
    """
    @endpoint Application.get_env(:lodestoner_ex, :endpoint)

    @type t :: %__MODULE__{message: String.t,
                           response: HTTPoison.Response.t,
                           error: HTTPoison.Error.t}

    defexception [ :message, :response, :error ]

    def exception([message: message]),
      do: %ClientError{message: message}

    def exception([response: response, path: path]) do
       msg = ~s{"Got an HTTP #{response.status_code} status from "} <>
              @endpoint <> path <> ~s{"}
       %ClientError{message: msg, response: response}
    end

    def exception([error: error, path: path]) do
      msg = ~s{Something terrible happend. HTTPoision failed with "} <>
        ~s{#{inspect error.reason}" trying to get #{@endpoint}#{path}}
      %ClientError{message: msg, error: error}
    end
  end

  defmodule REST do
    use HTTPoison.Base

    @endpoint Application.get_env(:lodestoner_ex, :endpoint)

    @standard_headers %{
      "Accept-Language" => "en-us.en;q=0.5",
      "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) Chrome/27.0.1453.116 Safari/537.36"
    } 

    defp process_url(url) do
      @endpoint <> url
    end

    defp process_request_headers(headers) when is_map(headers) do
      Map.merge(@standard_headers, headers)
      |> Map.to_list
    end

    defp process_request_headers(headers) do
      Map.to_list(@standard_headers) ++ headers
    end
  end
end
