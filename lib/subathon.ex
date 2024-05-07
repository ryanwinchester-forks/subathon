defmodule Subathon do
  @moduledoc """
  Subathon keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(Subathon.PubSub, topic, message)
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(Subathon.PubSub, topic)
  end

  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(Subathon.PubSub, topic)
  end
end
