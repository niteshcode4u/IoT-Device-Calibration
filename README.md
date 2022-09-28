# Elixir Interview Starter

## Using this Starter

This starter was created using erlang 22.3.4.12 and Elixir 1.11.3 but should be compatible
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

For this technical challenge, we will ask you to implement a calibration service using
`GenServer`s.

We have a pool chemistry monitor that is a WiFi-enabled IoT device that floats in your
swimming pool or spa and collects measurements of your water chemistry. We use these
measurements to make recommendations for what chemicals you should use to improve your
water quality, and in what quantities you should add them. However, before it can start
taking those measurements, the pool chemistry monitoring device first needs to be
calibrated. In order to calibrate, the server will orchestrate a process that executes
several commands on the device in sequence in order to calibrate it. This is what you'll
be implementing today!

### Communicating with the Device

Our device communicates with the server by sending and receiving messages. For the
purposes of this challenge, we'll assume we've already implemented the message sending and
receiving. To send the "calibrate" command to Kelli's device, for example, you can use
`device_messages.ex`:

```
DeviceMessages.send("kelli@email.com", "calibrate")
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

#### Timeline

You will work on completing the challenge partially with us, partially independently.
Here's what to expect:

1. We share the technical challenge prompt with you a day in advance.
2. On a preliminary call, we grant you access to fork the repo, go over any questions
   about what we are aiming to build (10-20 min), and pair on a "planning phase" (10-20
   min) where we will expect you to share your thoughts on how to approach this, maybe
   write some pseudo-code or draw some diagrams, and make sure you get off to a good
   start!
3. We let you do your thing and complete the challenge! You'll have 3 hours and can ask us
   as many questions as you want during that time. When you feel good about what you have,
   please upload your submission to GitHub as a private repository and grant us access to
   it. In order to prevent other candidates from seeing your work, please do not open a
   pull request against this repository. If you feel it absolutely necessary, you can
   still make changes after this time, but keep in mind this will negatively impact how we
   score your work.
4. We review and score your submission internally.
5. Optionally, we may choose to schedule a follow-up call with you and ask you to walk us
   through how your submission works and any tests you wrote (10-20 min).
6. ***\*\*Important!!\*\**** If we choose to schedule this call, we will also ask you to
   choose an Elixir-specific concept that you leveraged in your submission and prepare to
   give a short (5-10 min) explanation to us of how that concept works, as if you were
   introducing the concept to a junior engineer with limited exposure to Elixir. You
   don't need to bring any fancy presentation materials; we're just looking for you to
   demonstrate your ability to convey a concept you know well to an audience who does not
   know it at all. To that end, the concept you choose does not necessarily need to be
   unique to Elixir, but through your explanation, you should be able to convince us why
   the concept you chose is important to working with Elixir.

#### Submission Rubric

There aren't intended to be any tricks or "gotchas" with this challenge, and to that end,
we also aim to be fully transparent about how we will score your submission:

| Points | Description |
| ---- | ---- |
| --- | **Business Requirements** |
| 10 | `start/1` starts a new process and sends the `"startPrecheck1"` command |
| 3 | Handles Precheck 1 responses |
| 8 | `start_precheck_2/1` uses the existing process to send the `"startPrecheck2"` command |
| 3 | Handles Precheck 2 responses |
| 5 | Progresses automatically to send `"calibrate"` command when both Precheck 2 checks pass
| 3 | Handles Calibrated responses |
| 3 | `get_current_session/1` returns the current state of the `CalibrationSession`
| --- | **Implementation** |
| 3 | Correctly uses Supervisors and GenServers |
| 8 | Implements tests for the behavior of all the three API methods |
| 3 | Implements e2e flow test for happy path
| 1 | Makes effective use of any 3rd party packages
| --- | **Organization** |
| 6 | Before beginning, formulates and expresses a plan using pseudo-code, writing notes, drawing diagrams, or the like
| 2 | Arranges any directories, modules, and logic in a way that is consistent and intuitive
| 2 | Provides names for functions and variables that are clear and expressive
| 2 | Leaves intelligent git commit messages
| --- | **Presentation** |
| 4 | Provides an appropriate amount of documentation in the form of code comments
| 8 | Explains their implementation choices and walks through their submission clearly and confidently
| 2 | Reflects on any missteps or areas for improvement and is receptive to feedback shared
| 10 | Verbally articulates an Elixir concept of their choice in a way that would be easy to grasp for a junior engineer with limited exposure to Elixir
