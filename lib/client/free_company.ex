defmodule LodestonerEx.Client.FreeCompany do
  @moduledoc """
  Provides functions that retrieve Free Company data.
  """

  import LodestonerEx.Utils
  alias LodestonerEx.Client.ClientError

  @rest Application.get_env(:lodestoner_ex, :rest_client)

  @doc """
  Retrieve the Lodestone ID of a Free Company.

  ## Parameters
    - `server_name`: The server or world name, e.g. `"Gilgamesh"`
    - `full_fc_name`: FC name in full, searching by tag doesn't really work.
      e.g. `"Death and Taxes"`

  ## Returns
    - String.t The lodestone ID.

  ## Raises
    `LodestonerEx.Client.ClientError` if any of the following occur:

    - Lodestone returns a non-200 HTTP response.
    - No free companies are found by the search.
    - Multiple free companies are found by the search.

    The last reason generally means that the exact name
    does not exist on that world/server.  (Or that you 

  ## Examples
      iex> LodestonerEx.Client.FreeCompany.lodestone_id!("Gilgamesh", "Well Crap")
      ** (LodestonerEx.Client.ClientError) Found no such FC.

      iex> LodestonerEx.Client.FreeCompany.lodestone_id!("Gilgamesh", "Magitaint Mayhem")
      "9232238498621162014"
  """
  @spec lodestone_id!(String.t, String.t) :: String.t | no_return
  def lodestone_id!(server_name, full_fc_name) do
    path = "/freecompany?" <>
      URI.encode_query(%{
        "q" => full_fc_name,
        "worldname" => server_name
      })

    case @rest.get(path) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} ->
        found_fcs = Floki.find(body, ".player_name_area .player_name_gold a")
        |> Floki.attribute("href")
        cond do
          Enum.count(found_fcs) > 1 ->
            raise ClientError, message: "Found multiple FCs. Usually means no such FC exists."
          Enum.count(found_fcs) == 0 ->
            raise ClientError, message: "Found no such FC."
          true -> found_fcs
                  |> List.first
                  |> URI.parse 
                  |> Map.get(:path)
                  |> URI.path_to_segments
                  |> Enum.find(&Regex.match?(~r/^[0-9]+$/, &1))
        end
      {:ok,  response} ->
        raise ClientError, response: response, path: path
      {:error, error} ->
        raise ClientError, error: error, path: path
    end
  end

  @doc """
  Retrieves information for a Free Company.

  ## Parameters
    - `lodestone_id`: The FC Lodestone ID as a string.

  ## Returns
    - See Example.

  ## Raises
    `LodestonerEx.Client.ClientError` if any of the following occur:

    - Lodestone returns a non-200 HTTP response.

  ## Examples
			iex> LodestonerEx.Client.FreeCompany.info!("9232238498621162014")
			%{active: "Always", active_members: "501", estate_profile: nil,
				focus: ["Role-playing", "Leveling", "Casual", "Hardcore", "Dungeons",
				 "Guildhests", "Trials", "Raids", "PvP"],
				formed: %DateTime{calendar: Calendar.ISO, day: 24, hour: 20,
				 microsecond: {0, 0}, minute: 26, month: 8, second: 59, std_offset: 0,
				 time_zone: "Etc/UTC", utc_offset: 0, year: 2013, zone_abbr: "UTC"},
				name: "MagiTaint Mayhem", rank: %{last_month: "7", last_week: "5", now: "8"},
				recruitment: "Open",
				seeking: ["Tank", "Healer", "DPS", "Crafter", "Gatherer"],
				slogan: "A guild for lesbian/gay/bi/trans/ally folk.   To join us, you *MUST* apply at rtgc.enjin.com/ffxiv and request membership.   This app is ONLY a waitlist.",
				tag: "«TAINT»"}
  """

  @spec info!(String.t) :: map | no_return
  def info!(lodestone_id) do
    path = "/freecompany/" <> lodestone_id <> "/"
    case @rest.get(path) do
      {:ok, %HTTPoison.Response{body: html, status_code: 200}} -> 
        extract_fc_data(html)
      {:ok, response} ->
        raise ClientError, response: response, path: path
      {:error, error} ->
        raise ClientError, error: error, path: path
    end
  end

  defp extract_fc_data(html) do
    fc_table = Floki.parse(html)
    |> Floki.find(".table_style2 tr")
    |> Enum.reduce(%{}, fn(tr, acc) ->
      key = Floki.find(tr, "th") |> Floki.text
      value = Floki.find(tr, "td")
      Map.put(acc, key, value)
    end)

    [fc_name, fc_tag] = Map.get(fc_table, "Free Company Name\n«Company Tag»")
                        |> Floki.text
                        |> String.split("\n")

    formed = Map.get(fc_table, "Formed")
             |> Floki.find("script")
             |> List.first
             |> Floki.text
             |> parse_strfrtime_script

    active_members = Map.get(fc_table, "Active Members") |> Floki.text

    rank = Map.get(fc_table, "Rank")
           |> Floki.text
           |> String.replace(~r"[\n\t]", "")

    [rank_last_week, _, rank_last_month | _ ] = Map.get(fc_table, "Ranking")
         |> List.first
         |> elem(2)

    [rank_last_week] = Regex.run(~r"Rank: (\d+)", rank_last_week, capture: :all_but_first)
    [rank_last_month] = Regex.run(~r"Rank: (\d+)", rank_last_month, capture: :all_but_first)

    company_slogan = Map.get(fc_table, "Company Slogan") |> Floki.text

    [focus, seeking] = ["Focus", "Seeking"]
                       |> Enum.map(fn(key) ->
                         Map.get(fc_table, key)
                         |> Floki.find("img")
                         |> Floki.attribute("title")
                       end)
    active = Map.get(fc_table, "Active")
             |> Floki.text
             |> String.replace(~r"[\n\t]", "")

    recruitment = Map.get(fc_table, "Recruitment")
                  |> Floki.text
                  |> String.replace(~r"[\n\t]", "")

    estate_profile = if has_estate?(fc_table) do
      estate_profile(fc_table)
    else
      nil
    end

    %{
      name: fc_name,
      tag: fc_tag,
      formed: formed,
      active_members: active_members,
      rank: %{
        now: rank,
        last_week: rank_last_week,
        last_month: rank_last_month
      },
      slogan: company_slogan,
      focus: focus,
      seeking: seeking,
      active: active,
      recruitment: recruitment,
      estate_profile: estate_profile
    }
  end

  defp has_estate?(fc_table) do
    Map.get(fc_table, "Estate Profile")
    |> Floki.text
    |> String.match?(~r"no estate or plot"i)
  end

  defp estate_profile(fc_table) do
    cell_tags = Map.get(fc_table, "Estate Profile")
    |> List.first
    |> elem(2)

    %{
      name:     Enum.at(cell_tags, 0) |> Floki.text,
      address:  Enum.at(cell_tags, 2) |> Floki.text,
      greeting: Enum.at(cell_tags, 3) |> Floki.text
    }
  end

  @doc """
  Retrives the membership roster of an FC.

  Note that this is a pretty heavy operation.  Members are only shown
  50 at a time, and Lodestone is notoriously slow.  I've done my best by
  spawning all the requests and parsing via `Task.async/1` and reducing
  the results.  However, you'll be opening a lot of connections, so 
  be careful.

  ## Paramaters
    - `lodestone_id`: The free company's lodestone ID as a string.

  ## Returns
    A list of maps.  See examples.


  ## Examples
			iex(14)> LodestonerEx.Client.FreeCompany.member_roster!("9232238498621162014") |> Enum.count
			501
			iex(15)> LodestonerEx.Client.FreeCompany.member_roster!("9232238498621162014") |> List.first
			%{id: "6804197", name: "Alexander Valert",
				rank: %{id: "2", name: "Spoony Bard"}}
			iex(16)> LodestonerEx.Client.FreeCompany.member_roster!("9232238498621162014") |> List.last
			%{id: "9295239", name: "Rijo Zaba", rank: %{id: "5", name: "InLovingMemory"}}
  """
  @spec member_roster!(String.t) :: [map]
  def member_roster!(lodestone_id) do
    page_1_parsed = get_member_page(lodestone_id, 1)
                    |> Floki.parse

    compute_total_pages(page_1_parsed)
    |> (&Range.new(1, &1)).()
    |> Enum.map(fn (page_number) -> Task.async(fn ->
      if page_number == 1 do
        parse_member_page(page_1_parsed)
      else
        get_member_page(lodestone_id, page_number)
        |> Floki.parse
        |> parse_member_page
      end
    end) end)
    |> Enum.map(&Task.await(&1, 10_000))
    |> Enum.reduce([], fn(list, acc) -> acc ++ list end)
  end


  defp compute_total_pages(body) do
    Floki.find(body, ~s(a[rel="last"])) 
    |> Floki.attribute("href") 
    |> List.first 
    |> URI.parse 
    |> Map.get(:query) 
    |> URI.decode_query 
    |> Map.get("page") 
    |> String.to_integer
  end

  defp get_member_page(lodestone_id, page_number) do
    path = "/freecompany/#{lodestone_id}/member/?" <>
      URI.encode_query(%{"page" => Integer.to_string(page_number)})

    get_page_or_raise_client_error(path)
  end


  defp parse_member_page(body) do
    Floki.find(body, ".player_name_area")
    |> Enum.reduce([], fn (player_area, member_list) ->
      id = Floki.find(player_area, "a")
           |> Floki.attribute("href")
           |> List.first
           |> String.split("/")
           |> Enum.at(-2)

      name = Floki.find(player_area, "a")
             |> Floki.text

      rank_id = Floki.find(player_area, ".player_name_area")
                |> List.first
                |> Floki.find(".fc_member_status img")
                |> Floki.attribute("src")
                |> List.first
                |> (&Regex.run(~r"/(\d+).png", &1, capture: :all_but_first)).()
                |> List.first

      rank_name = Floki.find(player_area, ".fc_member_status")
                  |> Floki.text
                  |> String.replace(~r"[\n\t]", "")

      member = %{
        id: id,
        name: name,
        rank: %{
          id: rank_id,
          name: rank_name
        }
      }

      [ member | member_list ]
    end)
  end
end
