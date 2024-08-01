defmodule ReproductionWeb.ThingLive do
  @moduledoc false
  use ReproductionWeb, :live_view

  # in bytes
  @a_lot 10_000_000_000_000

  @impl true
  def mount(params, _session, socket) do
    upload_opts = [
      accept: ~w(.mp4 .mov),
      max_entries: 1,
      max_file_size: @a_lot,
      external: &presign_upload/2
    ]

    socket =
      socket
      |> assign(:thing, params["thing"])
      |> assign(:page_title, "Uploading")
      |> assign(:uploaded_files, [])
      |> assign(:form, to_form(%{}))
      |> allow_upload(:videos, upload_opts)

    {:ok, socket}
  end

  def presign_upload(_entry, socket) do
    {:ok, %{"url" => url, "id" => mux_id}, _} = create_mux_video()
    socket = assign(socket, :mux_id, mux_id)

    {:ok, %{uploader: "UpChunk", entrypoint: url}, socket}
  end

  def create_mux_video do
    client = Mux.client(
      System.fetch_env!("MUX_TOKEN_ID"),
      System.fetch_env!("MUX_TOKEN_SECRET")
    )

    Mux.Video.Uploads.create(client, %{
      "new_asset_settings" => %{"playback_policies" => ["public", "signed"], "encoding_tier" => "baseline"},
      "cors_origin" => "localhost/*"
    })
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :videos, ref)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :videos, fn _, meta ->
        {:ok, dbg(meta)}
      end)

    {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <p class="mb-5">
      <.link class="link" navigate={~p"/other"}>another page</.link>
      <.link :if={!@thing} class="link" navigate={~p"/thing"}>same, but different</.link>
      <.link :if={!!@thing} class="link" navigate={~p"/"}>nvm, i wanna go back</.link>
    </p>

    <.form for={@form} id="upload-form" phx-change="validate" phx-submit="save">
      <section
        class={"border-dotted border-2 border-gray-400 bg-gray-100 text-gray-700 p-4 rounded-lg flex flex-row gap-2
        #{if length(@uploads.videos.entries) >= @uploads.videos.max_entries, do: "hidden"}"}
        phx-drop-target={@uploads.videos.ref}
      >
        <p>Drop your files, or: </p>
        <.live_file_input upload={@uploads.videos} />
      </section>

      <section :for={entry <- @uploads.videos.entries} class="my-3 bg-gray-100 p-2 rounded-lg">
        <div class="flex gap-2 justify-between">
          <h2 class="font-bold text-sm"><%= entry.client_name %></h2>

          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
            class="hover:bg-gray-50 text-gray-800 rounded-full text-lg p-1"
            >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-4">
              <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <progress :if={entry.progress > 0} class="flex-grow bg-gray-50 rounded my-1" value={entry.progress} max="100">
          <%= entry.progress %>%
        </progress>

        <p :for={err <- upload_errors(@uploads.videos, entry)} class="text-red-500 text-xs">
          <%= error_to_string(err) %>
        </p>
      </section>

      <.button class="float-right mt-2 flex gap-2 items-center" type="submit">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-4">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5m-13.5-9L12 3m0 0 4.5 4.5M12 3v13.5" />
        </svg>
        Upload
      </.button>
    </.form>
    """
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
