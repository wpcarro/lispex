defmodule Lispex.Environment do
  @moduledoc """
  Abstract representation of an environment for a Lisp program.

  """

  def get do
    %{
      +: (&+/2),
      -: (&-/2),
      *: (&*/2),
      /: (&//2),

      sqrt: &:math.sqrt/1,
      sin: &:math.sin/1,
      cos: &:math.cos/1,

      abs: &Kernel.abs/1,

      car: fn([x | _]) -> x end,
      cdr: fn([_ | rest]) -> rest end,

      gt: &>/2,
      lt: &</2,
      gte: &>=/2,
      lte: &<=/2,
      eq: &==/2,

      message: &IO.inspect/1,
    }
  end
end
