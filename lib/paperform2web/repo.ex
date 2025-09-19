defmodule Paperform2web.Repo do
  use Ecto.Repo,
    otp_app: :paperform2web,
    adapter: Ecto.Adapters.Postgres
end
