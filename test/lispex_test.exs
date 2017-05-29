defmodule LispexTest do
  use ExUnit.Case
  doctest Lispex


  describe "read_from_tokens/1" do
    setup do
      simple_program =
        ["(", "setq", "x", "12", ")"]

      error_program =
        ["(", "setq", "x", "12"]

      nested_program_a =
        ["(", "setq", "x", "(", "+", "1", "2", ")", ")"]

      nested_program_b =
        "(setq x (if t (+ 5 5) 10))"

      {:ok,
       %{simple_program: simple_program,
         error_program: error_program,
         nested_program_a: nested_program_a,
         nested_program_b: nested_program_b,
       }
      }
    end

    test "works for simply nested, syntactically correct programs", %{simple_program: simple_program} do
      assert Lispex.read_from_tokens(simple_program) ==
        [:setq, :x, 12]
    end

    test "works for nested, syntactically correct programs", %{nested_program_a: a, nested_program_b: b} do
      assert Lispex.read_from_tokens(a) ==
        [:setq, :x, [:+, 1, 2]]

      assert Lispex.read_from_tokens(b) ==
        [:setq, :x, [:if, :t, [:+, 5, 5], 10]]
    end

    test "raises a ArgumentError for a syntactically incorrect program", %{error_program: error_program} do
      assert_raise ArgumentError, fn ->
        Lispex.read_from_tokens(error_program)
      end
    end

    test "raises a ArgumentError for an empty program" do
      assert_raise ArgumentError, fn ->
        Lispex.read_from_tokens([])
      end
    end
  end


  describe "parse_atom/1" do
    test "parses integers into integers" do
      assert Lispex.parse_atom("12") == 12
    end

    test "parses floats into floats" do
      assert Lispex.parse_atom("12.05") == 12.05
    end

    test "parses strings into atoms" do
      assert Lispex.parse_atom("symbol") == :symbol
    end
  end


  describe "tokenize/1" do
    setup do
      program =
        "(begin (define r 10) (* pi (* r r)))"

      {:ok, %{program: program}}
    end

    test "tokenizes input", %{program: program} do
      assert Lispex.tokenize(program) ==
        ["(", "begin", "(", "define", "r", "10", ")", "(", "*", "pi", "(", "*", "r", "r", ")", ")",
         ")"]
    end
  end
end
