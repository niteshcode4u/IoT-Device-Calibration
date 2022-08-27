defmodule ElixirInterviewStarter.DeviceMessages do
  @moduledoc """
  You shouldn't need to mofidy this module.

  This module provides an interface for mock-sending commands to devices.
  """

  @spec send(user_email :: String.t(), command :: String.t()) :: :ok
  @doc """
  Pretends to send the provided command to the Sutro Smart Monitor belonging to the
  provided user, which for the purposes of this challenge will always succeed.
  """
  def send(_user_email, _command), do: :ok
end
