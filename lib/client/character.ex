defmodule LodestonerEx.Client.Character do
  @moduledoc """
    Provides functionality surrounding both locating a character's
    lodestone ID and scraping character info for a particular lodestone
    id.
  """

  import LodestonerEx.Utils

  alias LodestonerEx.Client.ClientError
  @rest Application.get_env(:lodestoner_ex, :rest_client)

  @doc """
  Retrieve lodestone ID for given Server/Name Combo.

  ## Parameters
    - `server_name`: The server or world name, e.g. `"Gilgamesh"`
    - `full_character_name`: Space seperated first and last name,
      e.g. `"Derplander Default"`

  ## Returns
    - String.t The lodestone ID.

  ## Raises
    `LodestonerEx.Client.ClientError` if any of the following occur:

    - Lodestone returns a non-200 HTTP response.
    - No characters are found by the search.
    - Multiple characters are found by the search.

    The last reason generally means that the exact first and last name
    does not exist on that world/server.  However, some characters with the
    first or last name exist.

  ## Examples
      iex> LodestonerEx.Client.Character.lodestone_id!("Gilgamesh", "Krin Starrion")
      "6128486"

      iex> LodestonerEx.Client.Character.lodestone_id!("Gilgamesh", "Gobble Gobble")
      ** (LodestonerEx.Client.ClientError) Found multiple characters. Usually means no such character exists.

      iex> LodestonerEx.Client.Character.lodestone_id!("Gilgamesh", "Goobly Gook")
      ** (LodestonerEx.Client.ClientError) Found no such character.

      iex> LodestonerEx.Client.Character.lodestone_id!("Nonsense", "404_me")
      ** (LodestonerEx.Client.ClientError) "Got an HTTP 404 status from "http://na.finalfantasyxiv.com/lodestone/character?q=404_me&worldname=Nonsense"
  """
  @spec lodestone_id!(String.t, String.t) :: String.t | no_return
  def lodestone_id!(server_name, full_character_name) do
    path = "/character?" <> 
      URI.encode_query(%{
        "q" => full_character_name,
        "worldname" => server_name
      })

    

    found_characters = get_page_or_raise_client_error(path)
                       |> Floki.find(".player_name_area .player_name_gold a")
                       |> Floki.attribute("href")
    cond do
      Enum.count(found_characters) > 1 ->
        raise ClientError, message: "Found multiple characters. Usually means no such character exists."
      Enum.count(found_characters) == 0 ->
        raise ClientError, message: "Found no such character."
      true -> found_characters
              |> List.first
              |> URI.parse 
              |> Map.get(:path)
              |> URI.path_to_segments
              |> Enum.find(&Regex.match?(~r/^[0-9]+$/, &1))
    end
  end

  @doc """
  Retrieve the character info for a particular lodestone ID.
  ## Parameters
    - `lodestone_id`: The character lodestone ID as a string.

  ## Returns
    See examples.

  ## Raises
    `LodestonerEx.Client.ClientError` if any of the following occur:

    - Lodestone returns a non-200 HTTP response.

  ## Examples
			iex(1)> LodestonerEx.Client.Character.info!("15893891")
			%{attributes: %{dex: 24, int: 21, mnd: 17, pie: 21, str: 22, vit: 23},
				avatar_url: "http://img2.finalfantasyxiv.com/f/ccef11a9d5cb981df3c3c20f6d209229_284358f8eb4efc9095914e46798c6ab3fc0_96x96.jpg?1478634220",
				city_state: "Gridania", clan: "Midlander",
				classes: %{alchemist: %{level: "-", xp: %{current: "-", next: "-"}},
					arcanist: %{level: "-", xp: %{current: "-", next: "-"}},
					archer: %{level: "1", xp: %{current: "0", next: "300"}},
					armorer: %{level: "-", xp: %{current: "-", next: "-"}},
					astrologian: %{level: "-", xp: %{current: "-", next: "-"}},
					blacksmith: %{level: "-", xp: %{current: "-", next: "-"}},
					botanist: %{level: "-", xp: %{current: "-", next: "-"}},
					carpenter: %{level: "-", xp: %{current: "-", next: "-"}},
					conjurer: %{level: "-", xp: %{current: "-", next: "-"}},
					culinarian: %{level: "-", xp: %{current: "-", next: "-"}},
					dark_knight: %{level: "-", xp: %{current: "-", next: "-"}},
					fisher: %{level: "-", xp: %{current: "-", next: "-"}},
					gladiator: %{level: "-", xp: %{current: "-", next: "-"}},
					goldsmith: %{level: "-", xp: %{current: "-", next: "-"}},
					lancer: %{level: "-", xp: %{current: "-", next: "-"}},
					leatherworker: %{level: "-", xp: %{current: "-", next: "-"}},
					machinist: %{level: "-", xp: %{current: "-", next: "-"}},
					marauder: %{level: "-", xp: %{current: "-", next: "-"}},
					miner: %{level: "-", xp: %{current: "-", next: "-"}},
					pugilist: %{level: "-", xp: %{current: "-", next: "-"}},
					rogue: %{level: "-", xp: %{current: "-", next: "-"}},
					thaumaturge: %{level: "-", xp: %{current: "-", next: "-"}},
					weaver: %{level: "-", xp: %{current: "-", next: "-"}}},
				current_class: "Archer",
				elements: %{earth: 52, fire: 50, ice: 54, lightning: 52, water: 52, wind: 53},
				free_company: nil, gender: "male", grand_company: [nil, nil],
				guardian: "Halone, the Fury", minions: [], mounts: [],
				name: "Derplander Defaultus", nameday: "1st Sun of the 1st Astral Moon",
				portrait_url: "http://img2.finalfantasyxiv.com/f/ccef11a9d5cb981df3c3c20f6d209229_284358f8eb4efc9095914e46798c6ab3fl0_640x873.jpg?1478634220",
				race: "Hyur", server: "Coeurl", title: ""}
			iex> LodestonerEx.Client.Character.info!("404_me")
			** (LodestonerEx.Client.ClientError) "Got an HTTP 404 status from "http://na.finalfantasyxiv.com/lodestone/character/404_me/"
  """
  @spec info!(String.t) :: map | no_return
  def info!(lodestone_id) do
    path = "/character/" <> lodestone_id <> "/"
    case @rest.get(path) do
      {:ok, %HTTPoison.Response{body: body, status_code: 200}} -> 
        extract_character_data(body)
      {:ok, response} ->
        raise ClientError, response: response, path: path
      {:error, error} ->
        raise ClientError, error: error, path: path
    end
  end


  defp extract_character_data(unparsed_body) do
    body = Floki.parse(unparsed_body)

    name = Floki.find(body, ".player_name_txt h2 a") 
           |> Floki.text

    server = Floki.find(body, ".player_name_txt span")
      |> Floki.text
      |> String.trim
      |> String.replace(~r/[\(\)]/, "")

    title = Floki.find(body, ".chara_title") |> Floki.text

    [ race, clan, gender ] = Floki.find(body, ".chara_profile_title")
                             |> Floki.text
                             |> String.split(" / ")

    gender = case gender do
      "♂" -> "male"
      "♀" -> "female"
    end

    profile = Floki.find(body, ".chara_profile_footer .chara_profile_box_info")
              |> Enum.flat_map( fn (profile_box) ->
                titles = Floki.find(profile_box, ".txt") 
                        |> Enum.map(&Floki.text/1)
                values = Floki.find(profile_box, ".txt_name")
                List.zip([titles, values])
              end)
              |> Enum.into(%{})

    nameday    = profile |> Map.get("Nameday")    |> Floki.text
    guardian   = profile |> Map.get("Guardian")   |> Floki.text
    city_state = profile |> Map.get("City-state") |> Floki.text

    # This key can be absent so pattern match above would freak out
    # if we put it there.
    free_company = case Map.fetch(profile, "Free Company") do
      {:ok, fc_html} ->
        %{name: Floki.text(fc_html), 
         lodestone_id: fc_html
                       |> Floki.find("a")
                       |> Floki.attribute("href")
                       |> List.first
                       |> String.split("/")
                       |> Enum.at(-2)
        }
      :error ->
        nil
    end

    grand_company = case Map.get(profile, "Grand Company") do
      nil -> 
        [nil, nil]
      gc_html -> 
        [gc_name, gc_rank] = gc_html |> Floki.text |> String.split("/")
        %{name: gc_name, rank: gc_rank}
    end

    classes = character_info_class_list(body)

    attributes = character_attributes(body)

    elements = character_elements(body)

    {mounts, minions} = character_minions_and_mounts(body)

    avatar_url = Floki.find(body, ".player_name_txt .player_name_thumb img")
                 |> Floki.attribute("src")
                 |> List.first

    portrait_url = Floki.find(body, ".bg_chara_264 img")
                   |> Floki.attribute("src")
                   |> List.first

    current_class = character_current_class(body)

    %{
      name: name,
      server: server,
      title: title,
      race: race,
      clan: clan,
      gender: gender,
      nameday: nameday,
      guardian: guardian,
      city_state: city_state,
      free_company: free_company,
      grand_company: grand_company,
      classes: classes,
      attributes: attributes,
      elements: elements,
      minions: minions,
      mounts: mounts,
      avatar_url: avatar_url,
      portrait_url: portrait_url,
      current_class: current_class
    }
  end

  defp character_info_class_list(html) do
    html
    # Get class list rows
    |> Floki.find("table.class_list tr")
    # For every row, flat map the children.
    # This gives us a list of td elements.
    |> Enum.flat_map(&elem(&1, 2))
    # Now extract the text of each td, results in 
    # [class, level, xp, class, level, xp, ...]
    |> Enum.map(&Floki.text/1)
    # And feed into the recursive stuff below, filtering out empty "cell sets"
    |> _zip_class_data
  end

  defp _zip_class_data(class_list),
    do: _zip_class_data(class_list, %{})

  defp _zip_class_data([], class_data), do: class_data

  defp _zip_class_data(["", _level, _xp | tail], class_data), 
    do: _zip_class_data(tail, class_data)

  defp _zip_class_data([class, level, xp | tail], class_data) do
    class_key = String.downcase(class) 
                |> String.replace(" ", "_") 
                |> String.to_atom
    xp_map = cond do
      String.length(xp) == 0 -> nil
      true -> [current_xp, next_xp] = String.split(xp, " / ")
              %{current: current_xp, next: next_xp}
    end
    class_info = %{level: level, xp: xp_map}
    _zip_class_data(tail, Map.put(class_data, class_key, class_info))
  end

  defp character_attributes(html) do
    # This is an unordered list with an image for the attribute name
    # and text with the attribute value.
    Floki.find(html, "ul.param_list_attributes")
    |> List.first
    |> elem(2)
    |> Enum.map(fn (li) ->
      # Parse out the image source URI for attribute.
      attribute = Floki.find(li, "img")
        |> List.first
        |> Floki.attribute("src")
        |> List.first
        |> (&(Regex.run(~r/attribute_([a-z]+)\.png/, &1, [capture: :all_but_first]))).()
        |> List.first
        |> String.to_atom
      # Grab text of <li> tag.
      value = Floki.text(li) |> String.to_integer
      # Return as {:dex, "235"}
      {attribute, value}
    end)
    |> Enum.into(%{})
  end

  defp character_elements(html) do
    #Similar to attributes, this is an unordered list.
    Floki.find(html, "ul.param_list_elemental")
    |> List.first
    |> elem(2)
    |> Enum.map(fn (li) ->
      # These are a bit easier since there's a span with the element name.
      element = Floki.find(li, "span.help_text") 
                |> Floki.text
                |> String.downcase
                |> String.replace(" ", "_")
                |> String.to_atom

      value = Floki.find(li, "span.val")
              |> List.first
              |> Floki.text
              |> String.to_integer
      {element, value}
    end)
    |> Enum.into(%{})
  end

  defp character_minions_and_mounts(html) do
    [minions, mounts] = Floki.find(html, ".minion_box")
    extract = fn (box) ->
      Floki.find(box, "a")
      |> Enum.flat_map(&Floki.attribute(&1, "title"))
    end
    {extract.(minions), extract.(mounts)}
  end

  defp character_current_class(html) do
    # Extract the main "arm" category from it's tooltip 
    Floki.find(html, "#param_class_info_area " <>
                ".db-tooltip__l_main " <>
                ".db-tooltip__item__category")
    |> List.first
    |> Floki.text
    # All these basically strip out all the other possible words except the
    # class
    |> String.replace("Two-handed ", "")
    |> String.replace("One-handed ", "")
    |> String.replace("'s Arm", "")
    |> String.replace("'s Primary Tool", "")
    |> String.replace("'s Grimoire", "")
  end

  @doc """
  Scrape achievements for a particular lodestone ID.

  Note that this is a pretty heavy operation.  Achievements are only shown
  20 at a time, and Lodestone is notoriously slow.  I've done my best by
  spawning all the requests and parsing via `Task.async/1` and reducing
  the results.  However, you'll be opening a lot of connections, so 
  be careful.

  ## Paramaters
    - `lodestone_id`: The character's lodestone ID as a string.

  ## Returns
    A list of maps.  See examples.

	## Examples
			iex> LodestonerEx.Client.Character.achievements!("6128486") |> List.first
			%{date: %DateTime{calendar: Calendar.ISO, day: 25, hour: 3, microsecond: {0, 0},
				 minute: 59, month: 10, second: 51, std_offset: 0, time_zone: "Etc/UTC",
				 utc_offset: 0, year: 2016, zone_abbr: "UTC"},
				icon: "http://img.finalfantasyxiv.com/lds/pc/global/images/itemicon/63/63eff52f13b87097fd1ac2fc2bd5e9fbef35924c.png?1473652662",
				id: "1594", name: "Floor the Horde"}

			iex> LodestonerEx.Client.Character.achievements!("6128486") |> List.last
			%{date: %DateTime{calendar: Calendar.ISO, day: 10, hour: 20,
				 microsecond: {0, 0}, minute: 58, month: 1, second: 52, std_offset: 0,
				 time_zone: "Etc/UTC", utc_offset: 0, year: 2014, zone_abbr: "UTC"},
				icon: "http://img.finalfantasyxiv.com/lds/pc/global/images/itemicon/66/66ebf6f40f5d7259d4bf9cbb5b52bfb1aa77b06f.png?1473652658",
				id: "323", name: "All the More Region to Leve I"}

			iex> LodestonerEx.Client.Character.achievements!("6128486") |> Enum.count
			398
  """
  @spec achievements!(String.t) :: [map] | []
  def achievements!(lodestone_id) do
    page_1_parsed = get_ach_page(lodestone_id, 1)
                    |> Floki.parse

    compute_total_pages(page_1_parsed)
    |> (&Range.new(1, &1)).()
    |> Enum.map(fn (page_number) -> Task.async(fn ->
         if page_number == 1 do
           parse_achs(page_1_parsed)
         else
           get_ach_page(lodestone_id, page_number)
           |> Floki.parse
           |> parse_achs
         end
       end) end)
    |> Enum.map(&Task.await(&1, 10_000))
    |> Enum.reduce([], fn (list, acc) -> acc ++ list end)
  end

  defp get_ach_page(lodestone_id, page) do
    path = "/character/#{lodestone_id}/achievement/?" <>
      URI.encode_query(%{"filter" => "2", "page" => Integer.to_string(page)})

    get_page_or_raise_client_error(path)
  end

  defp compute_total_pages(body) do
    result = Floki.find(body, ".pagination .total")
             |> List.first
             |> Floki.text
             |> Float.parse
    
    total_achs = case result do
      :error     -> -1
      { num, _ } -> num
    end

    (total_achs / 20) |> Float.ceil |> round
  end

  defp parse_achs(body) do
    Floki.find(body, ".achievement_list li")
    |> Enum.reduce([], fn (list_item, achievements) ->
         id = list_item
              |> Floki.find(".ic_achievement a")
              |> Floki.attribute("href")
              |> List.first
              # "http://domain.com/lodestone/character/6128486/achievement/detail/{:id}/"
              |> String.split("/")
              |> Enum.at(-2)
         icon = list_item
                |> Floki.find(".ic_achievement img")
                |> Floki.attribute("src")
                |> List.first
         name = list_item
                |> Floki.find(".achievement_txt a")
                |> List.first
                |> Floki.text
         date = list_item
                |> Floki.find("script")
                |> List.first
                |> Floki.text
                |> parse_strfrtime_script
      [%{id: id, icon: icon, name: name, date: date } | achievements]
    end)
  end
end
