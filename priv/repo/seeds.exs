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
  profile =
    Repo.insert!(%Accounts.Profile{
      twitch_id: "93766092",
      twitch_username: "TheCoppinger",
      pfp_url:
        "https://static-cdn.jtvnw.net/jtv_user_pictures/b638380e-eef0-434d-a7e2-b6c68d7cb256-profile_image-70x70.png"
    })

  Repo.insert!(%Subathon.EndTime{end_time: ~U[2024-08-02 00:01:55.000000Z]})

  {:ok, _check_in} = Accounts.create_check_in(profile.id)
end)
