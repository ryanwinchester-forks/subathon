# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Subathon.Repo.insert!(%Subathon.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Subathon.Accounts
alias Subathon.Repo

Repo.transaction(fn ->
  Repo.insert!(%Subathon.EndTime{end_time: ~U[2024-08-02 00:01:55.000000Z]})

  profile_a =
    Repo.insert!(%Accounts.Profile{
      twitch_id: "93766092",
      twitch_username: "TheCoppinger",
      pfp_url:
        "https://static-cdn.jtvnw.net/jtv_user_pictures/b638380e-eef0-434d-a7e2-b6c68d7cb256-profile_image-70x70.png"
    })

  profile_b =
    Repo.insert!(%Accounts.Profile{
      twitch_id: "146616692",
      twitch_username: "RyanWinchester_TV",
      pfp_url:
        "https://static-cdn.jtvnw.net/jtv_user_pictures/6d112a99-ae43-4111-90ed-2da6cb7ed622-profile_image-300x300.png"
    })

  for date <- Date.range(~D[2024-05-03], ~D[2024-05-07]) do
    Repo.insert!(%Accounts.CheckIn{
      profile_id: profile_a.id,
      date_nz: date,
      inserted_at: DateTime.new!(date, ~T[12:00:00.000000])
    })

    Repo.insert!(%Accounts.CheckIn{
      profile_id: profile_b.id,
      date_nz: date,
      inserted_at: DateTime.new!(date, ~T[12:00:00.000000])
    })
  end
end)
