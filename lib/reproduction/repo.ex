defmodule Reproduction.Repo do
  use Ecto.Repo,
    otp_app: :reproduction,
    adapter: Ecto.Adapters.Postgres
end
