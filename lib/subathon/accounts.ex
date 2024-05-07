defmodule Subathon.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Subathon.Repo

  alias Subathon.Accounts.CheckIn
  alias Subathon.Accounts.Profile
  alias Subathon.Accounts.ProfileToken

  @doc """
  Broadcast successful events.
  """
  def broadcast({:ok, %CheckIn{id: id}} = result, event) do
    Subathon.broadcast("check_ins", {event, id})
    result
  end

  def broadcast(result, _event), do: result

  @doc """
  Lists check-ins.

  ## Examples

      iex> list_check_ins()
      [%CheckIn{}, %CheckIn{}]

  """
  def list_check_ins do
    Repo.all(from c in CheckIn, order_by: [desc: c.inserted_at])
  end

  @doc """
  Get a check in by its ID.

  ## Examples

      iex> get_check_in!(id)
      %CheckIn{}

  """
  def get_check_in!(check_in_id), do: Repo.get!(CheckIn, check_in_id)

  @doc """
  Creates a check-in.

  ## Examples

      iex> create_check_in(%{field: value})
      {:ok, %Profile{}}

      iex> create_check_in(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_check_in(profile_id) do
    %CheckIn{profile_id: profile_id}
    |> CheckIn.changeset(%{})
    |> Repo.insert()
    |> broadcast(:new_check_in)
  end

  @doc """
  Gets a profile by twitch_id.

  ## Examples

      iex> get_profile_by_twitch_id("foo@example.com")
      %Profile{}

      iex> get_profile_by_twitch_id("unknown@example.com")
      nil

  """
  def get_profile_by_twitch_id(twitch_id) when is_binary(twitch_id) do
    Repo.get_by(Profile, twitch_id: twitch_id)
  end

  @doc """
  Gets a single profile.

  Raises `Ecto.NoResultsError` if the Profile does not exist.

  ## Examples

      iex> get_profile!(123)
      %Profile{}

      iex> get_profile!(456)
      ** (Ecto.NoResultsError)

  """
  def get_profile!(id), do: Repo.get!(Profile, id)

  @doc """
  Creates a profile.

  ## Examples

      iex> create_profile(%{field: value})
      {:ok, %Profile{}}

      iex> create_profile(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_profile(attrs) do
    %Profile{}
    |> Profile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a profile.

  ## Examples

      iex> update_profile(profile, %{field: value})
      {:ok, %Profile{}}

      iex> update_profile(profile, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_profile(profile, attrs) do
    profile
    |> Profile.changeset(attrs)
    |> Repo.update()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_profile_session_token(profile) do
    {token, profile_token} = ProfileToken.build_session_token(profile)
    Repo.insert!(profile_token)
    token
  end

  @doc """
  Gets the profile with the given signed token.
  """
  def get_profile_by_session_token(token) do
    {:ok, query} = ProfileToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_profile_session_token(token) do
    Repo.delete_all(ProfileToken.by_token_and_context_query(token, "session"))
    :ok
  end
end
