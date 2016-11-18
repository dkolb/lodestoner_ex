defmodule LodestonerEx.Client.MOCKREST do
  @moduledoc false

  @root_dir    File.cwd!
  @fixture_dir Path.join(~w(#{@root_dir} test fixtures))

  def get_minimal_char,
    do: get!("/character/15893891").body

  def get_full_char,
    do: get!("/character/6128486").body

  def get_achievement(page),
    do: get!("/character/6128486/achievement?filter=2&page=#{page}").body

  def get_fc,
    do: get!("/freecompany/9232238498621162014").body

  def get_members(page),
    do: get!("/freecompany/9232238498621162014/member/?page=2").body

  def get!(path, options \\ []) do
    case get(path, options) do
      {:ok, response} -> response
      {:error, error} -> raise error
    end
  end

  def get(uri, _options \\ []) do
    %URI{path: path, query: query} = URI.parse(uri)
    path = URI.path_to_segments(path) 
           |> Enum.filter(&(String.length(&1) > 0))
    query = case is_nil(query) do
      false -> URI.decode_query(query)
      true -> nil
    end

    case path do
      ["character"]             -> 
        process_character_query(uri, query)
      ["6128486", "character"]  -> 
        {:ok, http_response_for("character_page_all_the_stuff.html")}
      ["15893891", "character"] -> 
        {:ok, http_response_for("character_page_no_stuff.html")}
      ["404_me", "character"]   ->
        {:ok, http_404}
      [ "achievement", "6128486", "character"] ->
        process_achievement_query(uri, query)
      [ "freecompany" ] ->
        process_free_company_query(uri, query)
      [ "9232238498621162014", "freecompany"] ->
        {:ok, http_response_for("free_company.html")}
      [ "member", "9232238498621162014", "freecompany"] ->
        process_fc_member_query(uri, query)
      _                         ->
        {:error, ArgumentError.exception(message: "Unexpected call get(#{uri})")} 
    end
  end

  defp process_character_query(uri, query) do
    case query do
      %{"q" => "Krin Starrion", "worldname" => "Gilgamesh"} ->
        {:ok, http_response_for("good_search.html")}
      %{"q" => "Goobly Gook", "worldname" => "Gilgamesh"} ->
        {:ok, http_response_for("bad_search_no_player.html")}
      %{"q" => "Gobble Gobble", "worldname" => "Gilgamesh"} ->
        {:ok, http_response_for("bad_search_multiple_player.html")}
      %{"q" => "404_me"} ->
        {:ok, http_404}
      _ ->
        {:error, ArgumentError.exception(message: "Unexpected call get(#{uri})")}
    end
  end

  defp process_achievement_query(uri, query) do
    case query do
      %{"filter" => "2", "page" => page} ->
        {:ok, http_response_for("achievement_page_#{String.pad_leading(page, 2, "0")}.html")}
      _ ->
        {:error, ArgumentError.exception(message: "Unexpected call get(#{uri})")}
    end
  end

  defp process_fc_member_query(uri, query) do
    case query do
      %{"page" => page} ->
        {:ok, http_response_for("fc_member_page_#{String.pad_leading(page, 2, "0")}.html")}
      _ ->
        {:error, ArgumentError.exception(message: "Unexpected call get(#{uri})")}
    end
  end

  defp process_free_company_query(uri, query) do
    case query do
      %{"q" => "Magitaint Mayhem", "worldname" => "Gilgamesh"} ->
        {:ok, http_response_for("fc_good_search.html")}
      %{"q" => "Well Crap", "worldname" => "Gilgamesh"} ->
        {:ok, http_response_for("fc_bad_search.html")}
      _ ->
        {:error, ArgumentError.exception(message: "Unexpected call get(#{uri})")}
    end
  end

  defp http_response_for(file) do
    case File.open(Path.join(@fixture_dir, file), [:read, :utf8]) do
      {:ok, file} -> 
        contents = IO.read(file, :all)
        File.close(file)
        %HTTPoison.Response{
          body:         contents,
          headers:      [{"Content-Type", "text/html; charset=UTF-8"}],
          status_code:  200}
      {:error, reason} ->
        {:error, ArgumentError.exception(message: "Couldn't open fixture #{file} for reason #{inspect reason}")}
    end
  end

  defp http_404 do
    case File.open(Path.join(@fixture_dir, "404.html"), [:read, :utf8]) do
      {:ok, file} -> 
        contents = IO.read(file, :all)
        File.close(file)
        %HTTPoison.Response{
          body:         contents,
          headers:      [{"Content-Type", "text/html; charset=UTF-8"}],
          status_code:  404}
      {:error, reason} ->
        {:error, ArgumentError.exception(message: "Couldn't open fixture 404.html for reason #{inspect reason}")}
    end
  end

end

