defmodule SubathonWeb.ProfileAuthController do
  use SubathonWeb, :controller

  alias Subathon.Accounts
  alias SubathonWeb.ProfileAuth

  @doc """
  Redirect to the OAuth2 provider's authorization URL.
  """
  def request(conn, params) do
    conn =
      if Map.has_key?(params, "check-in") do
        put_session(conn, :profile_return_to, ~p"/?check-in")
      else
        conn
      end

    authorize_url = twitch_client() |> OAuth2.Client.authorize_url!()
    redirect(conn, external: authorize_url)
  end

  @doc """
  Callback to handle the provider's redirect back with the code for access
  token.
  """
  def callback(conn, %{"code" => code}) do
    client = twitch_client()

    twitch_token_params = %{
      client_id: client.client_id,
      client_secret: client.client_secret,
      code: code,
      grant_type: "authorization_code",
      redirect_uri: client.redirect_uri
    }

    client =
      client
      |> OAuth2.Client.merge_params(twitch_token_params)
      |> OAuth2.Client.get_token!()

    %{body: %{"data" => [user_data]}} =
      client
      |> OAuth2.Client.put_header("client-id", client.client_id)
      |> OAuth2.Client.get!("/helix/users")

    %{"twitch_id" => twitch_id} = profile_attrs = profile_attrs("twitch", user_data)

    {:ok, profile} =
      case Accounts.get_profile_by_twitch_id(twitch_id) do
        nil -> Accounts.create_profile(profile_attrs)
        profile -> Accounts.update_profile(profile, profile_attrs)
      end

    ProfileAuth.login_profile(conn, profile)
  end

  # Build the Twitch OAuth2 client.
  defp twitch_client do
    url = SubathonWeb.Endpoint.url()
    config = Application.fetch_env!(:subathon, __MODULE__)

    client_id =
      Keyword.fetch!(config, :twitch_client_id) || raise "twitch_client_id not set"

    client_secret =
      Keyword.fetch!(config, :twitch_client_secret) || raise "twitch_client_secret not set"

    OAuth2.Client.new(
      # default
      strategy: OAuth2.Strategy.AuthCode,
      client_id: client_id,
      client_secret: client_secret,
      site: "https://api.twitch.tv",
      authorize_url: "https://id.twitch.tv/oauth2/authorize",
      redirect_uri: "#{url}/auth/callback",
      token_url: "https://id.twitch.tv/oauth2/token",
      token_method: :post,
      serializers: %{"application/json" => Jason}
    )
  end

  defp profile_attrs("twitch", user_data) do
    %{
      "display_name" => display_name,
      "profile_image_url" => profile_image_url,
      "id" => id
    } = user_data

    %{
      "twitch_id" => id,
      "twitch_username" => display_name,
      "pfp_url" => profile_image_url
    }
  end
end
