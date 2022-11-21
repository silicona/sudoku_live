defmodule SudokuLiveWeb.PageController do
  use SudokuLiveWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
