defmodule ElixirInterviewStarterTest do
  use ExUnit.Case
  doctest ElixirInterviewStarter

  alias ElixirInterviewStarter.CalibrationSupervisor

  setup [:clear_children_on_exit]

  # set up
  @user_email "nitesh@abc.com"

  test "it can go through the whole flow happy path" do
    {:ok, precheck1_resp} = ElixirInterviewStarter.start(@user_email)

    pid = @user_email |> String.to_atom() |> Process.whereis()

    Process.send(pid, %{"precheck1" => true}, [:noconnect])

    {:ok, state_after_precheck1} = ElixirInterviewStarter.get_current_session(@user_email)

    {:ok, precheck2_resp} = ElixirInterviewStarter.start_precheck_2(@user_email)

    Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])
    Process.send(pid, %{"submergedInWater" => true}, [:noconnect])

    {:ok, state_after_precheck2} = ElixirInterviewStarter.get_current_session(@user_email)

    Process.send(pid, %{"calibrated" => true}, [:noconnect])

    {:ok, state_after_calibration} = ElixirInterviewStarter.get_current_session(@user_email)

    assert precheck1_resp.user_email == String.to_atom(@user_email)
    assert precheck1_resp.calibration_state == "precheck1Started"
    assert state_after_precheck1.precheck_1
    assert state_after_precheck1.calibration_state == "precheck1Completed"

    assert precheck2_resp.calibration_state == "precheck2Started"
    assert state_after_precheck2.cartridge_status
    assert state_after_precheck2.submerged_in_water

    assert state_after_calibration == %ElixirInterviewStarter.CalibrationSession{
             calibrated: true,
             calibration_state: "calibrationCompleted",
             cartridge_status: true,
             precheck_1: true,
             precheck_2: true,
             submerged_in_water: true,
             user_email: String.to_atom(@user_email)
           }
  end

  test "start/1 creates a new calibration session and starts precheck 1" do
    {:ok, precheck1_resp} = ElixirInterviewStarter.start(@user_email)

    assert precheck1_resp.user_email == String.to_atom(@user_email)
    assert precheck1_resp.calibration_state == "precheck1Started"
  end

  test "start/1 returns an error when device send false at precheck 1" do
    ElixirInterviewStarter.start(@user_email)
    pid = @user_email |> String.to_atom() |> Process.whereis()
    Process.send(pid, %{"precheck1" => false}, [:noconnect])

    Process.sleep(10)

    # Process is being stop once failed from precheck 1 is received
    assert {:ok, nil} == ElixirInterviewStarter.get_current_session(@user_email)
  end

  test "start/1 returns an error when there is timeout at precheck 1" do
    ElixirInterviewStarter.start(@user_email)
    pid = @user_email |> String.to_atom() |> Process.whereis()
    Process.send(pid, :precheck1_timeout, [:noconnect])

    Process.sleep(10)

    # Process is being stop once failed from precheck 1 is received
    assert {:ok, nil} == ElixirInterviewStarter.get_current_session(@user_email)
  end

  test "start/1 returns an error if the provided user already has an ongoing calibration session" do
    {:ok, precheck1_resp1} = ElixirInterviewStarter.start(@user_email)

    assert precheck1_resp1.user_email == String.to_atom(@user_email)
    assert precheck1_resp1.calibration_state == "precheck1Started"

    assert {:error, "calibration session already exist"} ==
             ElixirInterviewStarter.start(@user_email)
  end

  test "start_precheck_2/1 starts precheck 2" do
    ElixirInterviewStarter.start(@user_email)

    @user_email
    |> String.to_atom()
    |> Process.whereis()
    |> Process.send(%{"precheck1" => true}, [:noconnect])

    {:ok, precheck2_resp} = ElixirInterviewStarter.start_precheck_2(@user_email)

    assert precheck2_resp.precheck_1
    assert precheck2_resp.calibration_state == "precheck2Started"
  end

  test "start/1 returns an error when device send cartridgeStatus as false at precheck 2" do
    ElixirInterviewStarter.start(@user_email)
    pid = @user_email |> String.to_atom() |> Process.whereis()
    Process.send(pid, %{"precheck1" => true}, [:noconnect])

    ElixirInterviewStarter.start_precheck_2(@user_email)
    Process.send(pid, %{"cartridgeStatus" => false}, [:noconnect])

    Process.sleep(10)

    # Process is being stop once false for cartridgeStatus at precheck 2 is received
    assert {:ok, nil} == ElixirInterviewStarter.get_current_session(@user_email)
  end

  test "start/1 returns an error when device send submergedInWater as false at precheck 2" do
    ElixirInterviewStarter.start(@user_email)
    pid = @user_email |> String.to_atom() |> Process.whereis()
    Process.send(pid, %{"precheck1" => true}, [:noconnect])

    ElixirInterviewStarter.start_precheck_2(@user_email)
    Process.send(pid, %{"submergedInWater" => false}, [:noconnect])

    Process.sleep(10)

    # Process is being stop once false for submergedInWater at precheck 2 is received
    assert {:ok, nil} == ElixirInterviewStarter.get_current_session(@user_email)
  end

  test "start/1 returns an error there is a timeout at precheck 2" do
    ElixirInterviewStarter.start(@user_email)
    pid = @user_email |> String.to_atom() |> Process.whereis()
    Process.send(pid, %{"precheck1" => true}, [:noconnect])

    ElixirInterviewStarter.start_precheck_2(@user_email)
    Process.send(pid, :precheck2_timeout, [:noconnect])

    Process.sleep(10)

    # Process is being stop once there is timeout while waiting for response from device at precheck 2
    assert {:ok, nil} == ElixirInterviewStarter.get_current_session(@user_email)
  end

  test "start_precheck_2/1 returns an error if the provided user does not have an ongoing calibration session" do
    assert {:error, "Calibration session does not exist"} ==
             ElixirInterviewStarter.start_precheck_2(@user_email)
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is not done with precheck 1" do
    ElixirInterviewStarter.start(@user_email)

    assert {:error, "Precheck 1 not completed or still pending"} ==
             ElixirInterviewStarter.start_precheck_2(@user_email)
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is already done with precheck 2" do
    ElixirInterviewStarter.start(@user_email)

    pid = @user_email |> String.to_atom() |> Process.whereis()
    Process.send(pid, %{"precheck1" => true}, [:noconnect])

    ElixirInterviewStarter.start_precheck_2(@user_email)

    Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])
    Process.send(pid, %{"submergedInWater" => true}, [:noconnect])

    assert {:error, "Precheck 2 for calibration session already completed"} ==
             ElixirInterviewStarter.start_precheck_2(@user_email)
  end

  test "get_current_session/1 returns the provided user's ongoing calibration session" do
    ElixirInterviewStarter.start(@user_email)

    assert {:ok,
            %ElixirInterviewStarter.CalibrationSession{
              calibrated: nil,
              calibration_state: "precheck1Started",
              cartridge_status: nil,
              precheck_1: nil,
              precheck_2: nil,
              submerged_in_water: nil,
              user_email: String.to_atom(@user_email)
            }} == ElixirInterviewStarter.get_current_session(@user_email)
  end

  test "get_current_session/1 returns nil if the provided user has no ongoing calibrationo session" do
    assert {:ok, nil} == ElixirInterviewStarter.get_current_session(@user_email)
  end

  test "Success: when calibrated successfully" do
    ElixirInterviewStarter.start(@user_email)
    pid = @user_email |> String.to_atom() |> Process.whereis()
    Process.send(pid, %{"precheck1" => true}, [:noconnect])

    ElixirInterviewStarter.start_precheck_2(@user_email)
    Process.send(pid, %{"submergedInWater" => true}, [:noconnect])
    Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])

    Process.send(pid, %{"calibrated" => true}, [:noconnect])

    {:ok, response_after_successful_calibration} =
      ElixirInterviewStarter.get_current_session(@user_email)

    assert response_after_successful_calibration == %ElixirInterviewStarter.CalibrationSession{
             calibrated: true,
             calibration_state: "calibrationCompleted",
             cartridge_status: true,
             precheck_1: true,
             precheck_2: true,
             submerged_in_water: true,
             user_email: String.to_atom(@user_email)
           }
  end

  test "Error: when timeout at calibration" do
    ElixirInterviewStarter.start(@user_email)
    pid = @user_email |> String.to_atom() |> Process.whereis()
    Process.send(pid, %{"precheck1" => true}, [:noconnect])

    ElixirInterviewStarter.start_precheck_2(@user_email)
    Process.send(pid, %{"submergedInWater" => true}, [:noconnect])
    Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])

    Process.send(pid, :calibration_timeout, [:noconnect])

    Process.sleep(10)

    # Process is being stop once there is timeout while waiting for device response at calibration label
    assert {:ok, nil} == ElixirInterviewStarter.get_current_session(@user_email)
  end

  test "Error: when device return calibration as false" do
    ElixirInterviewStarter.start(@user_email)
    pid = @user_email |> String.to_atom() |> Process.whereis()
    Process.send(pid, %{"precheck1" => true}, [:noconnect])

    ElixirInterviewStarter.start_precheck_2(@user_email)
    Process.send(pid, %{"cartridgeStatus" => true}, [:noconnect])
    Process.send(pid, %{"submergedInWater" => true}, [:noconnect])

    Process.send(pid, %{"calibrated" => false}, [:noconnect])

    Process.sleep(10)

    # Process is being stop once false for calibrated at calibration is received
    assert {:ok, nil} == ElixirInterviewStarter.get_current_session(@user_email)
  end

  defp clear_children_on_exit(_context) do
    CalibrationSupervisor
    |> DynamicSupervisor.which_children()
    |> Enum.each(fn {:undefined, pid, _type, _sup} ->
      DynamicSupervisor.terminate_child(CalibrationSupervisor, pid)
    end)

    :ok
  end
end
