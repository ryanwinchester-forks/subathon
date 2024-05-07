defmodule Subathon.Schema do
  @moduledoc """
  Schema definition for Subathon.
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      @primary_key {:id, UUIDv7.Type, autogenerate: true}
      @foreign_key_type UUIDv7.Type
      @timestamps_opts [type: :utc_datetime]
    end
  end
end
