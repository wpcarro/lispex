defmodule Lispex do
  @moduledoc """
  Lisp compiler written in Elixir.

  """

  alias Lispex.Environment

  @type ast :: [any] | any



  ################################################################################
  # Public API
  ################################################################################

  @doc """
  Accepts a Lisp `program` as input outputs its result. Any `opts` are forwarded to `Lispex.eval/2`
  unaltered. Consult `Lispex.eval/2` documentation for more information about the options.

  """
  @spec interpret(String.t, keyword) :: any
  def interpret(program, opts \\ []) do
    program
    |> parse()
    |> eval(opts)
  end


  @doc """
  Evaluates the `ast` and returns its output.

  """
  @spec eval(ast, opts :: [{:environment, map}]) :: any
  def eval(program, opts) do
    env =
      opts[:environment] || Environment.get()

    do_eval(program, env)
  end


  @doc """
  Receives a raw program as input and converts it into an AST.

  """
  @spec parse(String.t) :: ast
  def parse(program) do
    program
    |> tokenize()
    |> read_from_tokens()
  end


  @doc """
  Asserts syntactic compliance and parses atomic units into values.

  """
  @spec read_from_tokens([String.t]) :: ast
  def read_from_tokens(tokens) do
    do_read_from_tokens(tokens, [])
  end

  @doc """
  Receives an atomic unit from a Lisp program and attempts to parse it into either:

  # Output

    - integer

    - float

    - atom

  """
  @spec parse_atom(String.t) :: integer | float | atom
  def parse_atom(input) do
    case {parse_as_int(input), parse_as_float(input)} do
      {{:ok, int}, _}   -> int
      {_, {:ok, float}} -> float
      {_, _}            -> String.to_atom(input)
    end
  end

  @spec parse_as_int(String.t) :: {:ok, integer} | :error
  def parse_as_int(input) do
    try do
      {:ok, String.to_integer(input)}
    rescue
      _ -> :error
    end
  end

  @spec parse_as_float(String.t) :: {:ok, float} | :error
  def parse_as_float(input) do
    try do
      {:ok, String.to_float(input)}
    rescue
      _ -> :error
    end
  end


  @doc """
  Tokenizes the input program.

  """
  @spec tokenize(String.t) :: [String.t]
  def tokenize(input) do
    input
    |> String.replace("(", " ( ")
    |> String.replace(")", " ) ")
    |> String.split()
  end



  ################################################################################
  # Private Helpers
  ################################################################################

  @spec do_read_from_tokens([String.t], ast) :: ast
  defp do_read_from_tokens(["(" | rest], []) do
    do_read_from_tokens(rest, [[]])
  end


  @spec do_eval(ast, map) :: any
  defp do_eval(program, env)
  defp do_eval([:if, test, conseq, alt | rest], env) do
    if do_eval(test, env) do
      do_eval(conseq, env)
    else
      eval(alt, env)
    end
  end

  defp do_eval([:define, identifier, val | rest], env) do
    new_env =
      Map.put(env, identifier, do_eval(val, env))

    do_eval(rest, new_env)
  end

  defp do_eval([identifier | rest], env) when is_atom(identifier) do
    resolved =
      Map.get(env, identifier)

    do_eval([resolved | rest], env)
  end

  defp do_eval([literal | rest], env) do
    literal
  end

end
