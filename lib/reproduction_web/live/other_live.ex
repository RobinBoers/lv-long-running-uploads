defmodule ReproductionWeb.OtherLive do
  @moduledoc false
  use ReproductionWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Another page")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.link class="link" navigate={~p"/"}>nvm, uploading is way cooler</.link>

    <p class="my-10 text-gray-800">Nothing to see here. (Trust me.)</p>
    """
  end
end
