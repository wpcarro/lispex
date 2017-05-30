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
    do_read_from_tokens(tokens, nil)
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
    case {parse_as_int(input), parse_as_float(input), parse_as_bool(input)} do
      {{:ok, int}, _, _}   -> int
      {_, {:ok, float}, _} -> float
      {_, _, {:ok, bool}}  -> bool
      {_, _, _}            -> String.to_atom(input)
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


  @spec parse_as_bool(String.t) :: {:ok, boolean} | :error
  def parse_as_bool("t"), do: {:ok, true}
  def parse_as_bool("f"), do: {:ok, false}
  def parse_as_bool(_), do: :error


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

  @spec do_read_from_tokens([any], :queue.queue(any)) :: [any]
  defp do_read_from_tokens(tokens, queue)

  defp do_read_from_tokens([], queue),
    do: :queue.to_list(queue)

  defp do_read_from_tokens([")" | rest], queue),
    do: {:queue.to_list(queue), rest}

  defp do_read_from_tokens(["(" | rest], queue) do
    {sexp, remaining_tokens} =
      do_read_from_tokens(rest, :queue.new())

    queue =
      case queue do
        nil -> :queue.from_list(sexp)
        queue -> :queue.in(sexp, queue)
      end

    do_read_from_tokens(remaining_tokens, queue)
  end

  defp do_read_from_tokens([x | rest], queue) do
    parsed =
      parse_atom(x)

    do_read_from_tokens(rest, :queue.in(parsed, queue))
  end


  @spec do_eval(ast, map) :: any
  defp do_eval(program, env)
  defp do_eval([:if, test, conseq, alt | rest], env) do
    if do_eval(test, env) do
      do_eval(conseq, env)
    else
      do_eval(alt, env)
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

    apply(resolved, rest)
  end

  defp do_eval(literal, env) do
    literal
  end

end
