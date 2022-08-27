defmodule ElixirInterviewStarterTest do
  use ExUnit.Case
  doctest ElixirInterviewStarter

  test "it can go through the whole flow happy path" do
  end

  test "start/1 creates a new calibration session and starts precheck 1" do
  end

  test "start/1 returns an error if the provided user already has an ongoing calibration session" do
  end

  test "start_precheck_2/1 starts precheck 2" do
  end

  test "start_precheck_2/1 returns an error if the provided user does not have an ongoing calibration session" do
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is not done with precheck 1" do
  end

  test "start_precheck_2/1 returns an error if the provided user's ongoing calibration session is already done with precheck 2" do
  end

  test "get_current_session/1 returns the provided user's ongoing calibration session" do
  end

  test "get_current_session/1 returns nil if the provided user has no ongoing calibrationo session" do
  end
end
