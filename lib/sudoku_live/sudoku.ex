defmodule SudokuLive.Sudoku do

  @vals Enum.to_list(1..9)

  def add_error_board(boards_ko, error_board) do
    Enum.map(Enum.with_index(boards_ko), fn {lines_ko, index} = _item ->
      case index do
        0 ->
          Enum.at(boards_ko, 0)

        _ ->
          line = Enum.at(error_board, index) || []

          if Enum.empty?(line) || Enum.member?(lines_ko, line),
            do: lines_ko,
            else: lines_ko ++ [line]
      end
    end)
  end

  def flat_combis(aux, lines_ko \\ [], acc \\ []) do
    cond do
      is_integer(Enum.at(aux, 0)) && Enum.count(aux) == 9 && !Enum.member?(lines_ko, aux) ->
        acc ++ [aux]

      is_list(Enum.at(aux, 0)) ->
        Enum.reduce(aux, acc, fn sub_aux, acc ->
          flat_combis(sub_aux, lines_ko, acc)
        end)

      true ->
        acc
    end
  end

  def get_all_combis(posibles, aux \\ [], vals \\ nil) do
    vals = vals || @vals
    aux =
      if !Enum.empty?(Enum.at(posibles, 0)) && !Enum.empty?(vals) do
        for x <- Enum.at(posibles, Enum.count(aux)) do
          if Enum.member?(vals, x) do
            vals = vals -- [x]
            aux = aux ++ [x]

            get_all_combis(posibles, aux, vals)
          else
            aux
          end
        end
      else
        aux
      end

    Enum.uniq(aux)
  end

  def get_board(inicial, boards_ko \\ [], combi_group \\ nil) do

    case get_lines(inicial, boards_ko, combi_group) do
      {:ok, tablero} ->
        tablero

      {:ko, {tablero, combi_group}} ->

        boards_ko_post = add_error_board(boards_ko, tablero)

        if Enum.count(Enum.at(boards_ko_post, 1)) > 10 do
          nil
        else
          get_board(inicial, boards_ko_post, reset_combi_group(combi_group))
        end
    end
  end

  def get_col_mem(tablero) do
    Enum.reduce(tablero, [], fn fila, acc ->
      Enum.reduce(Enum.with_index(fila), acc, fn {val, i}, acc2 ->
        aux_mem = Enum.at(acc2, i)

        if !is_nil(aux_mem),
          do: List.replace_at(acc2, i, aux_mem ++ [val]),
          else: List.insert_at(acc2, i, [val])
      end)
    end)
  end

  def get_cuadrado_cell(id_fila, id_col), do: floor(id_fila / 3) * 3 + (floor(id_col / 3) + 1)

  def get_cuadrado_mem(tablero) do
    Enum.reduce(Enum.with_index(tablero), [], fn {fila, id_fila}, acc ->
      Enum.reduce(Enum.with_index(fila), acc, fn {val, id_col}, acc2 ->
        id_cua = get_cuadrado_cell(id_fila, id_col) - 1
        aux_mem = Enum.at(acc2, id_cua)

        if !is_nil(aux_mem),
          do: List.replace_at(acc2, id_cua, aux_mem ++ [val]),
          else: List.insert_at(acc2, id_cua, [val])
      end)
    end)
  end

  def get_group_ko(tablero) do
    Enum.map(Enum.to_list(0..8), fn i ->
      if i == 0, do: List.first(tablero), else: []
    end)
  end

  def get_lines(tablero, group_ko, combi_group \\ nil) do
    [current_line, posibles] = get_posibles(tablero)
    lines_ko = Enum.at(group_ko, current_line)

    combi_group =
      if is_nil(combi_group) do
        get_group_ko(tablero)
      else
        combi_group
      end

    combis =
      if Enum.empty?(Enum.at(combi_group, current_line)) do
        get_all_combis(posibles)
      else
        Enum.at(combi_group, current_line)
      end

    combis = flat_combis(combis, lines_ko)

    combi_group = List.replace_at(combi_group, current_line, combis)
    case get_line_vals(combis) do
      {:ok, line} ->
        tablero = tablero ++ [line]

        if Enum.count(tablero) == 9,
          do: {:ok, tablero},
          else: get_lines(tablero, group_ko, combi_group)

      {:ko, line} ->
        cond do
          Enum.empty?(line) ->
            {:ko, {tablero, combi_group}}

          true ->
            raise ArgumentError,
              message:
                "Nunca debería pasar por aqui porque get_line_vals da lineas enteras por las combis"
        end
    end
  end

  def get_line_vals(combis) do
    if !Enum.empty?(combis) do
      {:ok, Enum.random(combis)}
      # {:ok, List.first(combis)}
    else
      {:ko, []}
    end
  end

  def get_posibles(tablero) do
    mem = get_col_mem(tablero)
    mem_cua = get_cuadrado_mem(tablero)

    posibles = get_valores_posibles(mem, mem_cua)
    current_line = Enum.count(tablero)

    [current_line, posibles]
  end

  def get_sudoku do
    inicial = [Enum.shuffle(@vals)]
    get_board(inicial, get_group_ko(inicial))
  end

  def get_valores_posibles(cols, mem_cua) do
    Enum.map(Enum.with_index(cols), fn {col, id_col} ->
      Enum.count(col)
       |> (&get_cuadrado_cell(&1, id_col) - 1).()
       |> (&Enum.at(mem_cua, &1) || []).()
       |> (&Enum.uniq(&1 ++ col)).()
       |> (&@vals -- &1).()
    end)
  end

  def reset_combi_group(group) do
    Enum.map(Enum.with_index(group), fn {step, i} ->
      if i < 2, do: step, else: []
    end)
  end
end
