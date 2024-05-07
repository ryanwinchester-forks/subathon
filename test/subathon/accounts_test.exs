defmodule Subathon.AccountsTest do
  use Subathon.DataCase

  alias Subathon.Accounts

  import Subathon.AccountsFixtures
  alias Subathon.Accounts.{Profile, ProfileToken}

  describe "get_profile_by_email/1" do
    test "does not return the profile if the email does not exist" do
      refute Accounts.get_profile_by_email("unknown@example.com")
    end

    test "returns the profile if the email exists" do
      %{id: id} = profile = profile_fixture()
      assert %Profile{id: ^id} = Accounts.get_profile_by_email(profile.email)
    end
  end

  describe "get_profile_by_email_and_password/2" do
    test "does not return the profile if the email does not exist" do
      refute Accounts.get_profile_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the profile if the password is not valid" do
      profile = profile_fixture()
      refute Accounts.get_profile_by_email_and_password(profile.email, "invalid")
    end

    test "returns the profile if the email and password are valid" do
      %{id: id} = profile = profile_fixture()

      assert %Profile{id: ^id} =
               Accounts.get_profile_by_email_and_password(profile.email, valid_profile_password())
    end
  end

  describe "get_profile!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_profile!(-1)
      end
    end

    test "returns the profile with the given id" do
      %{id: id} = profile = profile_fixture()
      assert %Profile{id: ^id} = Accounts.get_profile!(profile.id)
    end
  end

  describe "register_profile/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_profile(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_profile(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_profile(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = profile_fixture()
      {:error, changeset} = Accounts.register_profile(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_profile(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers profiles with a hashed password" do
      email = unique_profile_email()
      {:ok, profile} = Accounts.register_profile(valid_profile_attributes(email: email))
      assert profile.email == email
      assert is_binary(profile.hashed_password)
      assert is_nil(profile.confirmed_at)
      assert is_nil(profile.password)
    end
  end

  describe "change_profile_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_profile_registration(%Profile{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_profile_email()
      password = valid_profile_password()

      changeset =
        Accounts.change_profile_registration(
          %Profile{},
          valid_profile_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_profile_email/2" do
    test "returns a profile changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_profile_email(%Profile{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_profile_email/3" do
    setup do
      %{profile: profile_fixture()}
    end

    test "requires email to change", %{profile: profile} do
      {:error, changeset} = Accounts.apply_profile_email(profile, valid_profile_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{profile: profile} do
      {:error, changeset} =
        Accounts.apply_profile_email(profile, valid_profile_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{profile: profile} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_profile_email(profile, valid_profile_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{profile: profile} do
      %{email: email} = profile_fixture()
      password = valid_profile_password()

      {:error, changeset} = Accounts.apply_profile_email(profile, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{profile: profile} do
      {:error, changeset} =
        Accounts.apply_profile_email(profile, "invalid", %{email: unique_profile_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{profile: profile} do
      email = unique_profile_email()
      {:ok, profile} = Accounts.apply_profile_email(profile, valid_profile_password(), %{email: email})
      assert profile.email == email
      assert Accounts.get_profile!(profile.id).email != email
    end
  end

  describe "deliver_profile_update_email_instructions/3" do
    setup do
      %{profile: profile_fixture()}
    end

    test "sends token through notification", %{profile: profile} do
      token =
        extract_profile_token(fn url ->
          Accounts.deliver_profile_update_email_instructions(profile, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert profile_token = Repo.get_by(ProfileToken, token: :crypto.hash(:sha256, token))
      assert profile_token.profile_id == profile.id
      assert profile_token.sent_to == profile.email
      assert profile_token.context == "change:current@example.com"
    end
  end

  describe "update_profile_email/2" do
    setup do
      profile = profile_fixture()
      email = unique_profile_email()

      token =
        extract_profile_token(fn url ->
          Accounts.deliver_profile_update_email_instructions(%{profile | email: email}, profile.email, url)
        end)

      %{profile: profile, token: token, email: email}
    end

    test "updates the email with a valid token", %{profile: profile, token: token, email: email} do
      assert Accounts.update_profile_email(profile, token) == :ok
      changed_profile = Repo.get!(Profile, profile.id)
      assert changed_profile.email != profile.email
      assert changed_profile.email == email
      assert changed_profile.confirmed_at
      assert changed_profile.confirmed_at != profile.confirmed_at
      refute Repo.get_by(ProfileToken, profile_id: profile.id)
    end

    test "does not update email with invalid token", %{profile: profile} do
      assert Accounts.update_profile_email(profile, "oops") == :error
      assert Repo.get!(Profile, profile.id).email == profile.email
      assert Repo.get_by(ProfileToken, profile_id: profile.id)
    end

    test "does not update email if profile email changed", %{profile: profile, token: token} do
      assert Accounts.update_profile_email(%{profile | email: "current@example.com"}, token) == :error
      assert Repo.get!(Profile, profile.id).email == profile.email
      assert Repo.get_by(ProfileToken, profile_id: profile.id)
    end

    test "does not update email if token expired", %{profile: profile, token: token} do
      {1, nil} = Repo.update_all(ProfileToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_profile_email(profile, token) == :error
      assert Repo.get!(Profile, profile.id).email == profile.email
      assert Repo.get_by(ProfileToken, profile_id: profile.id)
    end
  end

  describe "change_profile_password/2" do
    test "returns a profile changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_profile_password(%Profile{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_profile_password(%Profile{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_profile_password/3" do
    setup do
      %{profile: profile_fixture()}
    end

    test "validates password", %{profile: profile} do
      {:error, changeset} =
        Accounts.update_profile_password(profile, valid_profile_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{profile: profile} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_profile_password(profile, valid_profile_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{profile: profile} do
      {:error, changeset} =
        Accounts.update_profile_password(profile, "invalid", %{password: valid_profile_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{profile: profile} do
      {:ok, profile} =
        Accounts.update_profile_password(profile, valid_profile_password(), %{
          password: "new valid password"
        })

      assert is_nil(profile.password)
      assert Accounts.get_profile_by_email_and_password(profile.email, "new valid password")
    end

    test "deletes all tokens for the given profile", %{profile: profile} do
      _ = Accounts.generate_profile_session_token(profile)

      {:ok, _} =
        Accounts.update_profile_password(profile, valid_profile_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(ProfileToken, profile_id: profile.id)
    end
  end

  describe "generate_profile_session_token/1" do
    setup do
      %{profile: profile_fixture()}
    end

    test "generates a token", %{profile: profile} do
      token = Accounts.generate_profile_session_token(profile)
      assert profile_token = Repo.get_by(ProfileToken, token: token)
      assert profile_token.context == "session"

      # Creating the same token for another profile should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%ProfileToken{
          token: profile_token.token,
          profile_id: profile_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_profile_by_session_token/1" do
    setup do
      profile = profile_fixture()
      token = Accounts.generate_profile_session_token(profile)
      %{profile: profile, token: token}
    end

    test "returns profile by token", %{profile: profile, token: token} do
      assert session_profile = Accounts.get_profile_by_session_token(token)
      assert session_profile.id == profile.id
    end

    test "does not return profile for invalid token" do
      refute Accounts.get_profile_by_session_token("oops")
    end

    test "does not return profile for expired token", %{token: token} do
      {1, nil} = Repo.update_all(ProfileToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_profile_by_session_token(token)
    end
  end

  describe "delete_profile_session_token/1" do
    test "deletes the token" do
      profile = profile_fixture()
      token = Accounts.generate_profile_session_token(profile)
      assert Accounts.delete_profile_session_token(token) == :ok
      refute Accounts.get_profile_by_session_token(token)
    end
  end

  describe "deliver_profile_confirmation_instructions/2" do
    setup do
      %{profile: profile_fixture()}
    end

    test "sends token through notification", %{profile: profile} do
      token =
        extract_profile_token(fn url ->
          Accounts.deliver_profile_confirmation_instructions(profile, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert profile_token = Repo.get_by(ProfileToken, token: :crypto.hash(:sha256, token))
      assert profile_token.profile_id == profile.id
      assert profile_token.sent_to == profile.email
      assert profile_token.context == "confirm"
    end
  end

  describe "confirm_profile/1" do
    setup do
      profile = profile_fixture()

      token =
        extract_profile_token(fn url ->
          Accounts.deliver_profile_confirmation_instructions(profile, url)
        end)

      %{profile: profile, token: token}
    end

    test "confirms the email with a valid token", %{profile: profile, token: token} do
      assert {:ok, confirmed_profile} = Accounts.confirm_profile(token)
      assert confirmed_profile.confirmed_at
      assert confirmed_profile.confirmed_at != profile.confirmed_at
      assert Repo.get!(Profile, profile.id).confirmed_at
      refute Repo.get_by(ProfileToken, profile_id: profile.id)
    end

    test "does not confirm with invalid token", %{profile: profile} do
      assert Accounts.confirm_profile("oops") == :error
      refute Repo.get!(Profile, profile.id).confirmed_at
      assert Repo.get_by(ProfileToken, profile_id: profile.id)
    end

    test "does not confirm email if token expired", %{profile: profile, token: token} do
      {1, nil} = Repo.update_all(ProfileToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_profile(token) == :error
      refute Repo.get!(Profile, profile.id).confirmed_at
      assert Repo.get_by(ProfileToken, profile_id: profile.id)
    end
  end

  describe "deliver_profile_reset_password_instructions/2" do
    setup do
      %{profile: profile_fixture()}
    end

    test "sends token through notification", %{profile: profile} do
      token =
        extract_profile_token(fn url ->
          Accounts.deliver_profile_reset_password_instructions(profile, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert profile_token = Repo.get_by(ProfileToken, token: :crypto.hash(:sha256, token))
      assert profile_token.profile_id == profile.id
      assert profile_token.sent_to == profile.email
      assert profile_token.context == "reset_password"
    end
  end

  describe "get_profile_by_reset_password_token/1" do
    setup do
      profile = profile_fixture()

      token =
        extract_profile_token(fn url ->
          Accounts.deliver_profile_reset_password_instructions(profile, url)
        end)

      %{profile: profile, token: token}
    end

    test "returns the profile with valid token", %{profile: %{id: id}, token: token} do
      assert %Profile{id: ^id} = Accounts.get_profile_by_reset_password_token(token)
      assert Repo.get_by(ProfileToken, profile_id: id)
    end

    test "does not return the profile with invalid token", %{profile: profile} do
      refute Accounts.get_profile_by_reset_password_token("oops")
      assert Repo.get_by(ProfileToken, profile_id: profile.id)
    end

    test "does not return the profile if token expired", %{profile: profile, token: token} do
      {1, nil} = Repo.update_all(ProfileToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_profile_by_reset_password_token(token)
      assert Repo.get_by(ProfileToken, profile_id: profile.id)
    end
  end

  describe "reset_profile_password/2" do
    setup do
      %{profile: profile_fixture()}
    end

    test "validates password", %{profile: profile} do
      {:error, changeset} =
        Accounts.reset_profile_password(profile, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{profile: profile} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_profile_password(profile, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{profile: profile} do
      {:ok, updated_profile} = Accounts.reset_profile_password(profile, %{password: "new valid password"})
      assert is_nil(updated_profile.password)
      assert Accounts.get_profile_by_email_and_password(profile.email, "new valid password")
    end

    test "deletes all tokens for the given profile", %{profile: profile} do
      _ = Accounts.generate_profile_session_token(profile)
      {:ok, _} = Accounts.reset_profile_password(profile, %{password: "new valid password"})
      refute Repo.get_by(ProfileToken, profile_id: profile.id)
    end
  end

  describe "inspect/2 for the Profile module" do
    test "does not include password" do
      refute inspect(%Profile{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
