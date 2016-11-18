# LodestonerEx

[![Build Status](https://travis-ci.org/dkolb/lodestoner_ex.svg?branch=master)](https://travis-ci.org/dkolb/lodestoner_ex)

LodestonerEx/Lodestone allows you to easily retrieve live FFXIV lodestone data into an Elixir friendly structure.

### Adding to Your Project
Simply add as a hex dependency to your project.

Add `lodestoner_ex` to your list of dependencies in `mix.exs`:

```elixir        
def deps do        
  [{:lodestoner_ex, "~> 1.0.0"}]        
end        
```

LodestonerEx itself does not need to be added to the applications or be started. However, Floki and HTTPoison needs to be added to your applications list.  (Maybe.  Testing this soon in a project that'll depend on this.)

 ```elixir        
 def application do        
   [applications: [:httpoison, :floki]]        
 end        
 ```


### Getting Started

Let's take this fine example of a lodestone character!

!["Image of Final Fantasy 14 character on the Lodestone site.](https://github.com/dkolb/lodestoner_ex/raw/md-assets/lodestone_browser.png)

First, we'll need to identify his lodestone ID, which is a string of digits.

```elixir
iex(1)> alias LodestonerEx.Client.Character
LodestonerEx.Client.Character
iex(2)> Character.lodestone_id!("Gilgamesh", "Krin Starrion")
"6128486"
```

Next, we can take that ID and pull back a pretty extensive data structure with almost everything we'd ever want to know about a character.

```elixir
iex(3)> character = Character.info!(v)
... snip ...
iex(3)> character.grand_company
%{name: "Order of the Twin Adder", rank: "Second Serpent Lieutenant"}
iex(4)> character.grand_company
%{name: "Order of the Twin Adder", rank: "Second Serpent Lieutenant"}
iex(5)> character.minions |> Enum.filter(&(&1 =~ "Baby"))
["Baby Behemoth", "Baby Bun"]
iex(6)> character.mounts |> Enum.co
concat/1    concat/2    count/1     count/2
iex(6)> character.mounts |> Enum.count
13
```

Perhaps we're interested in the Free Company of a character?

```elixir
iex(7)> alias LodestonerEx.Client.FreeCompany
LodestonerEx.Client.FreeCompany
iex(8)> character.free_company
%{lodestone_id: "9232238498621162014", name: "MagiTaint Mayhem"}
iex(9)> fc_id = character.free_company.lodestone_id
iex(10)> free_company = FreeCompany.info!(fc_id)
%{active: "Always", active_members: "507", estate_profile: nil,
  focus: ["Role-playing", "Leveling", "Casual", "Hardcore", "Dungeons",
   "Guildhests", "Trials", "Raids", "PvP"],
  formed: %DateTime{calendar: Calendar.ISO, day: 24, hour: 20,
   microsecond: {0, 0}, minute: 26, month: 8, second: 59, std_offset: 0,
   time_zone: "Etc/UTC", utc_offset: 0, year: 2013, zone_abbr: "UTC"},
  name: "MagiTaint Mayhem", rank: %{last_month: "7", last_week: "8", now: "8"},
  recruitment: "Open",
  seeking: ["Tank", "Healer", "DPS", "Crafter", "Gatherer"],
  slogan: "A guild for lesbian/gay/bi/trans/ally folk.   To join us, you *MUST* apply at rtgc.enjin.com/ffxiv and request membership.   This app is ONLY a waitlist.",
  tag: "«TAINT»"}
iex(11)> FreeCompany.member_roster!("9232238498621162014") |> Enum.count
507
iex(12)> FreeCompany.member_roster!("9232238498621162014") |> List.first
%{id: "6354563", name: "Alexander Heart", rank: %{id: "2", name: "Spoony Bard"}}
```

Please see the [hex package documentation](https://hexdocs.pm/lodestoner_ex/) for more information.
