# IoT Devide Calibration

This starter is created using erlang 22.3.4.12 and Elixir 1.11.3 but should be compatible
with other versions as well. This project supports managing your erlang and Elixir
installations with [asdf](https://github.com/asdf-vm/asdf) (with the
[asdf-erlang](https://github.com/asdf-vm/asdf-erlang) and
[asdf-elixir](https://github.com/asdf-vm/asdf-elixir) plugins) if you choose.

After forking and cloning the repository, install dependencies:

```mix deps.get```

Then compile the project:

```mix compile```

Then you can start the interactive Elixir shell:

```iex -S mix```

## Calibrating a Pool Chemistry Monitoring Device

An implemention of a calibration service using `GenServer`s.

Let's say there is a pool chemistry monitor that is a WiFi-enabled IoT device that floats in your swimming pool or spa and collects measurements of your water chemistry. We use these measurements to make recommendations for what chemicals you should use to improve your water quality, and in what quantities you should add them. However, before it can start taking those measurements, the pool chemistry monitoring device first needs to be calibrated. In order to calibrate, the server will orchestrate a process that executes several commands on the device in sequence in order to calibrate it. This is what you'll be implementing today!

### Communicating with the Device

Our device communicates with the server by sending and receiving messages. For the
purposes of this challenge, we'll assume we've already implemented the message sending and
receiving. To send the "calibrate" command to Kelli's device, for example, you can use
`device_messages.ex`:

```
DeviceMessages.send("abc@yxz.com", "calibrate")
```

We'll also assume that when the server receives a new message from a device, it knows how
to find any ongoing calibration process for that device and forward the message to that
`GenServer` process (i.e. with `Process.send/3`), so all you need to do is implement
callbacks to handle those messages.

We would like you to implement the API that is stubbed out on
`elixir_interview_starter.ex`, which has three methods: `start/1`, `start_precheck_2/1`
and `get_current_session/1`. These methods should give a consumer everything it needs to
calibrate a user's device without needing to know any of the details of what is involved
in that process. We have already written up documentation in the code for how each of
these methods should look and behave, but before diving in to the code, let's talk about
what the three steps of calibration are.

### Steps of Calibration

For a visual reference for these same steps, see
[calibration-flow.pdf](calibration-flow.pdf).

#### 1. Precheck 1

Precheck 1 is the first step of calibration where the device verifies the status of
various parts of its own hardware. From the server's perspective, calibration begins when
a client calls `start/1`, the first of the three API methods we ask you to implement.

During this step, the server is responsible for sending the command `"startPrecheck1"` to
the device and then waiting for it to perform its checks.

If the hardware checks pass, the device will respond with `%{"precheck1" => true}`. If
there is a problem with the hardware, the device will respond with `%{"precheck1" =>
false}`. If we do not receive a response back within **30 seconds**, we consider
calibration a failure.

#### 2. Precheck 2

If Precheck 1 succeeds, we start Precheck 2 once the user places their device in the
water. For Precheck 2, the device verifies that its cartridge is inserted properly and
that the device is sufficiently submerged in water. From the server's perspective,
calibration is on hold until the client calls `start_precheck_2/1`, the second of the
three API methods we ask you to implement.

During this step, the server is responsible for sending the command `"startPrecheck2"` to
the device and then waiting for it to perform its checks.

The device will respond individually with `%{"cartridgeStatus" => boolean()}` and
`%{"submergedInWater" => boolean()}` indicating whether or not each check passed or
failed. If we do not receive a response back within **30 seconds**, or we see one of the
checks fail, we consider calibration a failure. If both checks pass, we say Precheck 2
succeeds and automatically proceed to the next step.

#### 3. Calibrate

Once we've finished both Precheck steps, we start the actual LED calibration of the
device. From the server perspective, this step follows automatically from the previous
one.

During this step, the server is responsible for sending the command `"calibrate"` to the
device and then waiting for it to try to calibrate.

If the device calibrates successfully, it will respond with `%{"calibrated" => true}`. If
there is a problem, it will respond with `%{"calibrated" => false}`. If we do not receive
a response back within **100 seconds**, we consider calibration a failure.

Once this step succeeds, calibration is complete and the server's job is done!

### Challenge Criteria

To complete this challenge, you will need to implement the side of this process that is
managed on the server. At a high level, a successful application will be able to:

- start a supervisor to oversee Calibration processes
- manage `GenServer` processes for individual `CalibrationSession`s that exist for the
  entire lifespan of the `CalibrationSession`s
- implement logic to communicate with the pool chemistry monitoring device (send commands
  and handle message responses or timeouts) to walk through each step of Calibration

You are allowed to use whatever resources you would like and add whichever additional
packages you feel necessary. You can also ask for as much clarification as you feel you
need at any time.

#### Test Coverage

![Test coverage after development changes](https://user-images.githubusercontent.com/20892499/192726085-c60c48c7-64d6-445c-a733-cbd682f3135f.png)


