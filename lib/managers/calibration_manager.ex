defmodule ElixirInterviewStarter.Managers.CalibrationManager do
  @moduledoc """
  To handle the state of device calibration status
  """

  # Structure of state is struct of `ElixirInterviewStarter.CalibrationSession`

  use GenServer, restart: :transient

  @precheck1_timeout Application.compile_env(:elixir_interview_starter, :precheck1_timeout)
  @precheck2_timeout Application.compile_env(:elixir_interview_starter, :precheck2_timeout)
  @calibration_timeout Application.compile_env(:elixir_interview_starter, :calibration_timeout)
  @completed_states ~w(precheck1Completed precheck2Completed calibrationCompleted)

  alias ElixirInterviewStarter.CalibrationSession
  alias ElixirInterviewStarter.DeviceMessages

  # Client APIs #############################################################

  @spec start_link(atom | {:global, any} | {:via, atom, any}) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(user_email) do
    GenServer.start_link(__MODULE__, %CalibrationSession{user_email: user_email}, name: user_email)
  end

  @spec get_calibration_session(binary) :: any
  def get_calibration_session(user_email) do
    user_email
    |> String.to_atom()
    |> GenServer.whereis()
    |> case do
      nil -> {:ok, nil}
      pid -> GenServer.call(pid, :get_calibration_session)
    end
  end

  @spec start_precheck_2(binary) :: any
  def start_precheck_2(user_email) do
    user_email
    |> get_calibration_session()
    |> case do
      {:ok, %_{precheck_1: nil, precheck_2: nil}} ->
        {:error, "Precheck 1 not completed or still pending"}

      {:ok, %_{precheck_1: true, precheck_2: nil}} ->
        GenServer.call(String.to_atom(user_email), :start_precheck_2)

      {:ok, %_{precheck_1: true, precheck_2: true}} ->
        {:error, "Precheck 2 for calibration session already completed"}

      _ ->
        {:error, "Calibration session does not exist"}
    end
  end

  @impl GenServer
  def init(calibration_session) do
    {:ok, %{calibration_session | calibration_state: "initiated"}, {:continue, :start_precheck_1}}
  end

  # Call Handlers #############################################################

  @impl GenServer
  def handle_continue(:start_precheck_1, calibration_session) do
    Process.send_after(self(), :precheck1_timeout, @precheck1_timeout)
    DeviceMessages.send(calibration_session.user_email, "precheck1Started")
    calibration_session = %{calibration_session | calibration_state: "precheck1Started"}

    {:noreply, calibration_session}
  end

  @impl GenServer
  def handle_call(:get_calibration_session, _from, calibration_session) do
    {:reply, {:ok, calibration_session}, calibration_session}
  end

  def handle_call(:start_precheck_2, _from, calibration_session) do
    Process.send_after(self(), :precheck2_timeout, @precheck2_timeout)
    DeviceMessages.send(calibration_session.user_email, "precheck2Started")
    calibration_session = %{calibration_session | calibration_state: "precheck2Started"}

    {:reply, {:ok, calibration_session}, calibration_session}
  end

  @impl true
  def handle_info(%{"precheck1" => true}, calibration_session) do
    {:noreply, %{calibration_session | calibration_state: "precheck1Completed", precheck_1: true}}
  end

  @impl true
  def handle_info(%{"precheck1" => false}, calibration_session) do
    {:stop, :normal, %{calibration_session | calibration_state: "precheck1Failed"}}
  end

  @impl GenServer
  def handle_info(
        :precheck1_timeout,
        %CalibrationSession{calibration_state: "precheck1Started"} = calibration_session
      ) do
    {:stop, :normal, %{calibration_session | calibration_state: "precheck1Timeout"}}
  end

  @impl GenServer
  def handle_info(
        :precheck1_timeout,
        %CalibrationSession{calibration_state: "initiated"} = calibration_session
      ) do
    {:noreply, calibration_session}
  end

  @impl GenServer
  def handle_info(
        :precheck2_timeout,
        %CalibrationSession{calibration_state: "precheck2Started"} = calibration_session
      ) do
    {:stop, :normal, %{calibration_session | calibration_state: "precheck2Timeout"}}
  end

  @impl GenServer
  def handle_info(
        %{"cartridgeStatus" => false},
        %CalibrationSession{calibration_state: "precheck2Started"} = calibration_session
      ) do
    {:stop, :normal, %{calibration_session | calibration_state: "cartridgeStatusFailed"}}
  end

  @impl GenServer
  def handle_info(
        %{"cartridgeStatus" => true},
        %CalibrationSession{calibration_state: "precheck2Started"} = calibration_session
      ) do
    calibration_session = %{calibration_session | cartridge_status: true}

    case calibration_session.submerged_in_water do
      true ->
        Process.send_after(self(), :calibration_timeout, @calibration_timeout)
        DeviceMessages.send(calibration_session.user_email, "calibrate")

        {:noreply,
         %{calibration_session | calibration_state: "calibrationStarted", precheck_2: true}}

      nil ->
        {:noreply, calibration_session}
    end
  end

  @impl GenServer
  def handle_info(
        %{"submergedInWater" => false},
        %CalibrationSession{calibration_state: "precheck2Started"} = calibration_session
      ) do
    {:stop, :normal, %{calibration_session | calibration_state: "submergedInWaterFailed"}}
  end

  @impl GenServer
  def handle_info(
        %{"submergedInWater" => true},
        %CalibrationSession{calibration_state: "precheck2Started"} = calibration_session
      ) do
    calibration_session = %{calibration_session | submerged_in_water: true}

    case calibration_session.cartridge_status do
      true ->
        Process.send_after(self(), :calibration_timeout, @calibration_timeout)
        DeviceMessages.send(calibration_session.user_email, "calibrate")

        {:noreply,
         %{calibration_session | calibration_state: "calibrationStarted", precheck_2: true}}

      nil ->
        {:noreply, calibration_session}
    end
  end

  @impl GenServer
  def handle_info(
        _calibration_statetimeout,
        %CalibrationSession{calibration_state: calibration_state} = calibration_session
      )
      when calibration_state in @completed_states do
    {:noreply, calibration_session}
  end

  @impl GenServer
  def handle_info(
        :calibration_timeout,
        %CalibrationSession{calibration_state: "calibrationStarted"} = calibration_session
      ) do
    {:stop, :normal, %{calibration_session | calibration_state: "calibrateTimeout"}}
  end

  @impl true
  def handle_info(%{"calibrated" => true}, calibration_session) do
    {:noreply,
     %{calibration_session | calibration_state: "calibrationCompleted", calibrated: true}}
  end

  @impl true
  def handle_info(%{"calibrated" => false}, calibration_session) do
    {:stop, :normal, %{calibration_session | calibration_state: "calibrationFailed"}}
  end
end
