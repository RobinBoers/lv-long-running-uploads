defmodule ReproductionWeb.SlowWriter do
  @moduledoc false
  use ReproductionWeb, :upload_writer

  require Logger

  @impl true
  def init(opts) do
    {:ok, %{
      total: 0,
      level: Keyword.fetch!(opts, :level),
      timeout: Keyword.fetch!(opts, :timeout)
    }}
  end

  @impl true
  def meta(state) do
    Map.take(state, [:level, :timeout])
  end

  @impl true
  def write_chunk(data, state) do
    size = byte_size(data)
    Logger.log(state.level, "received chunk of #{size} bytes")

    Process.sleep(state.timeout)
    {:ok, %{state | total: state.total + size}}
  end

  @impl true
  def close(state, reason) do
    Logger.log(state.level, "closing upload after #{state.total} bytes}, #{inspect(reason)}")

    Process.sleep(state.timeout)
    {:ok, state}
  end
end
