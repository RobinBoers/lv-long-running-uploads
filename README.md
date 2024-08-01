# Long running uploads via external uploaders cause problems when reusing websocket connections

Clean repo to reproduce issue: https://git.dupunkto.org/axcelott/liveview-reproduce-bug

Steps to reproduce:

- Start a long-running upload.
- Remount the current LiveView during upload (click "same, but different").

This should create a new LiveView process that reuses the existing websocket connection. The new LiveView again sets up uploads.

However, on the frontend, the JavaScript happily keeps uploading and sending messages to the over the existing websocket connection, to *the new LiveView process*. This new LiveView process doesn't have the old upload state, thus crashes like this:

```crash
** (KeyError) key "phx-F-e1tog74Q2dEAgB" not found in: %{"phx-F-e1wlp0SMNl9giB" => :videos}
    :erlang.map_get("phx-F-e1tog74Q2dEAgB", %{"phx-F-e1wlp0SMNl9giB" => :videos})
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/upload.ex:196: Phoenix.LiveView.Upload.get_upload_by_ref!/2
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/upload.ex:126: Phoenix.LiveView.Upload.update_progress/4
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/channel.ex:176: anonymous fn/4 in Phoenix.LiveView.Channel.handle_info/2
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/channel.ex:1419: Phoenix.LiveView.Channel.write_socket/4
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/channel.ex:174: Phoenix.LiveView.Channel.handle_info/2
```

A similar thing happens when navigating to another LiveView. Steps to reproduce:

- Start a long-running upload.
- Navigate away (click "another page").

In this case, the new LiveView process didn't call `allow_uploads`, and thus doesn't have an uploading state, raising this error when the JavaScript happily reports upload progress:

```crash
** (ArgumentError) no uploads have been allowed on LiveView named ReproductionWeb.OtherLive
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/upload.ex:195: Phoenix.LiveView.Upload.get_upload_by_ref!/2
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/upload.ex:126: Phoenix.LiveView.Upload.update_progress/4
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/channel.ex:176: anonymous fn/4 in Phoenix.LiveView.Channel.handle_info/2
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/channel.ex:1419: Phoenix.LiveView.Channel.write_socket/4
    (phoenix_live_view 1.0.0-rc.6) lib/phoenix_live_view/channel.ex:174: Phoenix.LiveView.Channel.handle_info/2
```

I would expect running uploads to either:

- Terminate when navigating away.
- Block the page (show a warning like "are you sure you want to leave this page, there are unsaved changes", see <https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeunload_event>).
