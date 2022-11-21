defmodule SudokuLive.SudokuTest do
  use SudokuLive.DataCase

  alias SudokuLive.Sudoku

  describe "Sudoku" do
    @describetag :wip

    @tablero [[6, 8, 5, 4, 7, 9, 1, 3, 2]]
    @tablero2 [[1, 2, 3, 4, 5, 6, 7, 8, 9], [9, 8, 7, 3, 2, 1, 6, 5, 4]]
    @tablero3 [
      [9, 7, 2, 8, 6, 1, 4, 3, 5],
      [1, 3, 4, 2, 5, 7, 6, 8, 9],
      [5, 6, 8, 3, 4, 9, 1, 2, 7]
    ]

    test "add_error_board" do
      res = Sudoku.add_error_board(Sudoku.get_group_ko(@tablero2), @tablero2)

      assert res == [
               [1, 2, 3, 4, 5, 6, 7, 8, 9],
               [[9, 8, 7, 3, 2, 1, 6, 5, 4]],
               [],
               [],
               [],
               [],
               [],
               [],
               []
             ]

      res = Sudoku.add_error_board(res, @tablero2 ++ [[2, 4]])

      assert res == [
               [1, 2, 3, 4, 5, 6, 7, 8, 9],
               [[9, 8, 7, 3, 2, 1, 6, 5, 4]],
               [[2, 4]],
               [],
               [],
               [],
               [],
               [],
               []
             ]
    end

    test "flat_combis" do
      [_, posibles] = Sudoku.get_posibles(@tablero2)

      combis = Sudoku.get_all_combis(posibles)

      flat = Sudoku.flat_combis(combis, [])
      assert Enum.count(flat) >= 0

      flat_con_ko = Sudoku.flat_combis(combis, [Enum.at(flat, 0)])
      assert Enum.count(flat) == Enum.count(flat_con_ko) + 1
    end

    test "get_all_combis" do
      [_, posibles] = Sudoku.get_posibles(@tablero)

      res = Sudoku.get_all_combis(posibles)

      assert Enum.count(res) == Enum.count(Enum.at(posibles, 0))
    end

    test "get_board" do
      tablero = Sudoku.get_board(@tablero, Sudoku.get_group_ko(@tablero))

      assert Enum.count(tablero) == 9
    end

    test "get_board ok con segunda vuelta" do
      # {:ko, [[9, 1, 4, 3, 7, 6, 2, 8, 5], [2, 3, 5, 1, 4, 8, 6, 7, 9], [6, 7, 8, 2, 5, 9, 1, 3, 4], [1, 2, 3, 4, 6, 5, 7, 9, 8], [4, 5, 6, 8, 9, 7, 3, 1, 2]]}
      inicial = [[9, 1, 4, 3, 7, 6, 2, 8, 5]]

      tablero = Sudoku.get_board(inicial, Sudoku.get_group_ko(inicial))

      assert Enum.count(tablero) == 9

      # {last, _} = List.pop_at(tablero, -1)
      # assert last == [9, 4, 1, 7, 8, 5, 6, 2, 3]

      # Enum.each(tablero, fn line -> assert Enum.count(Enum.uniq(line)) == 9 end)
    end

    test "get_board inicial aleatorio ok hasta que falle" do
      inicial = [Enum.shuffle(Enum.to_list(1..9))]

      tablero = Sudoku.get_board(inicial, Sudoku.get_group_ko(inicial))

      assert Enum.count(tablero) == 9
    end

    test "get_board ko lineas no correctas" do
      # inicial = [[1, 3, 5, 7, 9, 2, 4, 6, 8]]
      for _x <- 0..20 do
        inicial = Enum.shuffle(Enum.to_list(9..1))

        res = Sudoku.get_board([inicial], Sudoku.get_group_ko(inicial))

        assert res != nil
      end
    end

    test "get_col_mem" do
      res = Sudoku.get_col_mem(@tablero2)

      assert res == [[1, 9], [2, 8], [3, 7], [4, 3], [5, 2], [6, 1], [7, 6], [8, 5], [9, 4]]

      res = Sudoku.get_col_mem(@tablero3)

      assert res == [
               [9, 1, 5],
               [7, 3, 6],
               [2, 4, 8],
               [8, 2, 3],
               [6, 5, 4],
               [1, 7, 9],
               [4, 6, 1],
               [3, 8, 2],
               [5, 9, 7]
             ]
    end

    test "get_col_mem de lines_ko" do
      lines = [[2, 1, 4, 5, 7, 3], [4, 3, 5, 6, 1, 2], [7, 9, 6, 8], [8, 7], []]
      res = Sudoku.get_col_mem(lines)

      assert res == [[2, 4, 7, 8], [1, 3, 9, 7], [4, 5, 6], [5, 6, 8], [7, 1], [3, 2]]
    end

    test "get_cuadrado_cell" do
      assert Sudoku.get_cuadrado_cell(0, 0) == 1
      assert Sudoku.get_cuadrado_cell(1, 1) == 1
      assert Sudoku.get_cuadrado_cell(2, 0) == 1
      assert Sudoku.get_cuadrado_cell(2, 2) == 1

      assert Sudoku.get_cuadrado_cell(1, 7) == 3
      assert Sudoku.get_cuadrado_cell(3, 0) == 4
      assert Sudoku.get_cuadrado_cell(3, 3) == 5

      assert Sudoku.get_cuadrado_cell(5, 8) == 6

      assert Sudoku.get_cuadrado_cell(7, 1) == 7
    end

    test "get_cuadrado_mem" do
      res = Sudoku.get_cuadrado_mem(@tablero2)

      assert res == [[1, 2, 3, 9, 8, 7], [4, 5, 6, 3, 2, 1], [7, 8, 9, 6, 5, 4]]

      res = Sudoku.get_cuadrado_mem(@tablero3)

      assert res == [
               [9, 7, 2, 1, 3, 4, 5, 6, 8],
               [8, 6, 1, 2, 5, 7, 3, 4, 9],
               [4, 3, 5, 6, 8, 9, 1, 2, 7]
             ]
    end

    test "get_lines inicial correcto" do
      {:ok, tablero} = Sudoku.get_lines(@tablero, Sudoku.get_group_ko(@tablero))

      assert Enum.count(tablero) == 9
      Enum.each(tablero, fn line -> assert Enum.count(Enum.uniq(line)) == 9 end)
    end

    test "get_lines inicial aleatorio ok y ko" do
      inicial = [Enum.shuffle(Enum.to_list(1..9))]
      {state, tablero} = Sudoku.get_lines(inicial, Sudoku.get_group_ko(inicial))

      if state == :ok do
        assert Enum.count(tablero) == 9

        assert Enum.count(Enum.uniq(tablero)) == 9, "las filas deberían ser diferentes"

        assert Enum.count(Enum.uniq(Sudoku.get_col_mem(tablero))) == 9,
               "las columnas deberían ser diferentes"

        Enum.each(tablero, fn line -> assert Enum.count(Enum.uniq(line)) == 9 end)

        Enum.each(Sudoku.get_col_mem(tablero), fn col ->
          assert Enum.count(Enum.uniq(col)) == 9
        end)
      else
        assert Enum.count(tablero) < 9
      end
    end

    test "get_lines ko lineas no correctas" do
      inicial = [Enum.shuffle(Enum.to_list(1..9)), Enum.shuffle(Enum.to_list(1..9))]

      {:ko, {tablero, _}} = Sudoku.get_lines(inicial, Sudoku.get_group_ko(inicial))

      assert Enum.count(tablero) < 9
    end

    test "get_posibles" do
      [num_line, res] = Sudoku.get_posibles(@tablero2)

      assert num_line == 2

      assert res == [
               [4, 5, 6],
               [4, 5, 6],
               [4, 5, 6],
               [7, 8, 9],
               [7, 8, 9],
               [7, 8, 9],
               [1, 2, 3],
               [1, 2, 3],
               [1, 2, 3]
             ]
    end

    test "get_sudoku" do
      Sudoku.get_sudoku()
      |> Enum.uniq()
      |> Enum.map(fn line ->

        assert Enum.count(line) == 9
        line
      end)
      |> (&assert Enum.count(&1) == 9).()
    end

    test "get_valores_posibles" do
      mem = Sudoku.get_col_mem(@tablero2)
      mem_cua = Sudoku.get_cuadrado_mem(@tablero2)
      res = Sudoku.get_valores_posibles(mem, mem_cua)

      assert res == [
               [4, 5, 6],
               [4, 5, 6],
               [4, 5, 6],
               [7, 8, 9],
               [7, 8, 9],
               [7, 8, 9],
               [1, 2, 3],
               [1, 2, 3],
               [1, 2, 3]
             ]
    end
  end
end
