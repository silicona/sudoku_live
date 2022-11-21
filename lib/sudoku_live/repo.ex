defmodule SudokuLive.Repo do
  use Ecto.Repo,
    otp_app: :sudoku_live,
    adapter: Ecto.Adapters.Postgres
end
