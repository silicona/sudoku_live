defmodule SudokuLiveWeb.SudokuLive do
  use SudokuLiveWeb, :live_view

  alias SudokuLive.Sudoku
  @val_ko_visible 10
  @val_ko 20
  @val_ok 90
  @difs %{
    "Chônin" => 70,
    "Daimio" => 50,
    "Samurai" => 35,
    "Shögun" => 25
  }

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_vals()
     |> assign_sudoku(connected?(socket))
     |> assign_check_corregir(false)
     |> assign_check_posibles(false)}
  end

  def add_value_to_sudoku(socket, %{line: line, col: col, value: value}) do
    id_line = String.to_integer(line)
    id_col = String.to_integer(col)

    valor =
      case Integer.parse(value) do
        {0, _} ->
          set_negative_value(socket.assigns.board, id_line, id_col)

        {valor, _} ->
          ko_visible = is_ko_visible?(socket.assigns.board, valor, id_line, id_col)
          value_ok = get_value(socket.assigns.sudoku, id_line, id_col) == valor

          valor = if value_ok, do: valor + @val_ok, else: valor + @val_ko
          if ko_visible, do: valor - @val_ko_visible, else: valor

        :error ->
          set_negative_value(socket.assigns.board, id_line, id_col)
      end

    line =
      Enum.at(socket.assigns.board, id_line)
      |> List.replace_at(id_col, valor)

    socket
    |> assign(:board, socket.assigns.board |> List.replace_at(id_line, line))
    |> assign_resp()
  end

  def assign_check_corregir(socket, active \\ true) do
    socket
    |> assign(:corregir_check, if(active, do: [checked: true], else: []))
    |> assign(:corregir_on, if(active, do: "corregir", else: ""))
    |> assign_resp(if active, do: "Corrección activada")
  end

  def assign_check_posibles(socket, active \\ true) do
    socket
    |> assign(:posibles_check, if(active, do: [checked: true], else: []))
    |> assign(:posibles, active)
    |> assign_resp(if active, do: "Posibilidades automáticas activada")
  end

  def assign_sudoku(socket, connected \\ true) do
    if !connected do
      socket
      |> assign(:board, nil)
    else
      sudoku = Sudoku.get_sudoku()

      socket
      |> assign(:sudoku, sudoku)
      |> assign(:board, sudoku |> delete_vals(socket.assigns.dif))
    end
  end

  def assign_resp(socket, resp \\ nil), do: socket |> assign(:resp, resp)

  def assign_vals(socket) do
    socket
    |> assign(:val_ok, @val_ok)
    |> assign(:val_ko, @val_ko)
    |> assign(:val_ko_visible, @val_ko_visible)
    |> assign(:difs, @difs)
    |> assign(:dif, Map.get(@difs, "Daimio"))
  end

  def check_end(socket) do
    fin_ok =
      Enum.reduce_while(socket.assigns.board, %{fin: true, board_c: []}, fn line, acc ->
        fin =
          Enum.reduce(line, acc.fin, fn cell, acc_i ->
            if cell <= 0 or (cell > 9 and cell <= @val_ok - @val_ko_visible),
              do: false,
              else: acc_i
          end)

        if fin do
          {:cont,
           acc
           |> Map.put(:board_c, acc.board_c ++ [flat_values(line)])
           |> Map.put(:fin, fin)}
        else
          {:halt, Map.put(acc, :fin, fin)}
        end
      end)
      |> Enum.reduce(true, fn {key, value}, fin ->
        case key do
          :board_c ->
            case Enum.count(value) do
              0 ->
                false

              num ->
                cond do
                  num != Enum.count(Enum.at(value, 0)) ->
                    false

                  num != Enum.count(Enum.uniq(value)) ->
                    false

                  true ->
                    true
                end
            end

          _ ->
            if fin, do: value, else: fin
        end
      end)

    if fin_ok do
      assign_resp(socket, "Has terminado el sudoku, chapa blanda")
    else
      socket |> assign_resp(check_false_end(socket))
    end
  end

  def check_false_end(socket) do
    if !Enum.member?(List.flatten(socket.assigns.board), 0) do
      "Parece que algo está mal en el sudoku, simio dominante"
    end
  end

  def delete_vals(sudoku, dif) do
    Enum.map(sudoku, fn line ->
      Enum.map(line, fn val ->
        if :rand.uniform(100) / dif >= 1, do: 0, else: val
        # if :rand.uniform(2) == 1, do: 0, else: val
      end)
    end)
  end

  def flat_values(vals), do: Enum.map(vals, fn val -> if val > 0, do: rem(val, 10), else: val end)

  def get_cell_order(id_line, id_col), do: rem(id_line, 3) * 3 + rem(id_col, 3)

  def get_posibilidades(socket, %{line: line, col: col}) do
    id_line = line |> String.to_integer()
    id_col = col |> String.to_integer()
    board = socket.assigns.board

    mensaje =
      if socket.assigns.posibles do
        vals =
          ((Enum.at(board, id_line) ++ Enum.at(Sudoku.get_col_mem(board), id_col)) ++
             Enum.at(Sudoku.get_cuadrado_mem(board), Sudoku.get_cuadrado_cell(id_line, id_col) - 1))
          |> Enum.reduce([], fn val, acc ->
            val = val |> rem(10)
            if val > 0 && val < 10, do: acc ++ [val], else: acc
          end)
          |> Enum.uniq()

        if !Enum.empty?(vals) do
          "Los valores posibles son: #{Enum.join(Enum.to_list(1..9) -- vals, ", ")}"
        end
      end

    socket
    |> assign_resp(mensaje)
  end

  def get_value(board, id_line, id_col), do: Enum.at(Enum.at(board, id_line), id_col)

  def handle_event("sudoku-blur", data, socket) do
    {
      :noreply,
      socket
      |> add_value_to_sudoku(keys_to_atoms(data))
      |> check_end()
    }
  end

  def handle_event("sudoku-click", data, socket) do
    {
      :noreply,
      socket
      |> get_posibilidades(keys_to_atoms(data))
    }
  end

  def handle_event("sudoku-reiniciar", _data, socket) do
    title =
      @difs
      |> Enum.find(fn {_key, val} -> val == socket.assigns.dif end)
      |> elem(0)

    {
      :noreply,
      socket
      |> assign_sudoku(connected?(socket))
      |> assign_check_corregir(false)
      |> assign_check_posibles(false)
      |> assign_resp("Sudoku reiniciado (dif. #{title})")
    }
  end

  def handle_event("sudoku-asignar-dif", data, socket) do
    {:noreply,
     socket
     |> assign(:dif, String.to_integer(data["value"]))}
  end

  def handle_event("sudoku-change-corregir", data, socket) do
    {:noreply,
     socket
     |> assign_check_corregir(String.to_integer(data["value"] || "0") > 0)}
  end

  def handle_event("sudoku-change-posibles", data, socket) do
    {:noreply,
     socket
     |> assign_check_posibles(String.to_integer(data["value"] || "0") > 0)}
  end

  def is_ko_visible?(board, val, id_line, id_col) do
    cond do
      is_value_repeat?(Enum.at(board, id_line), val, id_col) ->
        true

      is_value_repeat?(Enum.at(Sudoku.get_col_mem(board), id_col), val, id_line) ->
        true

      is_value_repeat?(
        Enum.at(
          Sudoku.get_cuadrado_mem(board),
          Sudoku.get_cuadrado_cell(id_line, id_col) - 1,
          get_cell_order(id_line, id_col)
        ),
        val
      ) ->
        true

      true ->
        false
    end
  end

  def is_value_repeat?(line, val, id_ref \\ nil) do
    Enum.filter(Enum.with_index(flat_values(line)), fn {cell, i} ->
      if !is_nil(id_ref) and i == id_ref and cell == val do
        false
      else
        cell == val
      end
    end)
    |> Enum.count() > 0
  end

  def keys_to_atoms(map) do
    cond do
      is_map(map) ->
        for {key, val} <- map, into: %{}, do: {String.to_atom(key), keys_to_atoms(val)}

      is_list(map) ->
        map |> Enum.map(&keys_to_atoms/1)

      true ->
        map
    end
  end

  def set_negative_value(board, id_line, id_col),
    do: if(get_value(board, id_line, id_col) > -1, do: -1, else: 0)
end
