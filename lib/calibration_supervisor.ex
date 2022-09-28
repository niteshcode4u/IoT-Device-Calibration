defmodule ElixirInterviewStarter.CalibrationSupervisor do
  @moduledoc false

  use GenServer

  @supervisor __MODULE__

  alias ElixirInterviewStarter.Managers.CalibrationManager
  # alias ElixirInterviewStarter.CalibrationSession

  @doc """
  Starts the supervisor.
  """
  def start_link(opts) do
    DynamicSupervisor.start_link(@supervisor, opts, name: @supervisor)
  end

  @impl GenServer
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Ensures to initiate calibration with provided `user_email` with `calibration_supervisior`
  """
  def start_calibration_session(user_email) do
    case DynamicSupervisor.start_child(
           @supervisor,
           {CalibrationManager, String.to_atom(user_email)}
         ) do
      {:ok, _pid} -> CalibrationManager.get_calibration_session(user_email)
      {:error, {:already_started, _pid}} -> {:error, "calibration session already exist"}
    end
  end
end
