<div align="center">

# Nerves LED Blinking tutorial

A complete tutorial of how to deploy a Nerves application on a Raspberry Pi
</div>

<br></br>

## Why?

Nerves is a simple to use (IoT) framework 
that is rock-solid thanks to it running on the BEAM (Erlang virtual machine). 
However, in order to start building
and working on systems it's useful to have a knowledge 
of how the whole framework fits together 
and how it interacts with the wider Elixir ecosystem.

Although I have refered to Nerves as a framework, Nerves is better described as a **platform**, in that you write pure Elixir code and almost never
call Nerves functions. Nerves packages up your code and creates Linux firmware image that includes everything you need and nothing more. When the Raspberry
Pi has finished booting Nerves starts your Elixir application and its dependencies.

Nerves includes lots of features such as Over-The-Air firmware updates that means you can truly "fire and forget".

## What?

This application is deliberately built with extra features expandability in mind. *There are simpler tutorials* for
Blinking lights, but we're aiming to give a broad overview of Nerves and Elixir.

A simple step-by-step that will show you how to:
- **Create** a Nerves application from scratch
- **Add** a simple module to blink an LED
- **Deploy** your application on a Raspberry Pi
- **Tweaking** your application and redeploying Over-The-Air

*For simple Nerves applications, thats it! But (**Intermediate knowledge of Elixir recommended)** we can also add a web-based GUI by*:
- **Refractoring** the blinking LED control so we can call it from another BEAM application
- **Creating** a Nerves **poncho** project structure.
- **Creating** a simple Phoenix web application.
- **Implementing** a GUI that switches your light on and off.
- **Configuring** networking so you can access your application.

## Who?
This example is for people who are ***complete beginners*** with Nerves but some Elixir knowledge will be useful for understanding whats going on.
For the second part of the guide a basic knowledge of how `GenServers` and the BEAM works is recommened, although you should still be able to follow
along and work out whats going on.

If you get stuck, open an *issue* on this GitHub repository and we'll try and fix it. If you get stuck, it's probaly an issue with our guide!

## How?

These instructions will demonstrate how to get started from scratch.

### 0. Pre-requisites

1. Ensure you have `Elixir` installed on your **`localhost`** (_main computer_)
see: 
[elixir-lang.org/install](https://elixir-lang.org/install.html) <br />

Check by running the following command in your terminal: <br />
```sh
elixir -v
```
You should see:
```
Erlang/OTP 23 [erts-11.0] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1]
Elixir 1.10.3 (compiled with Erlang/OTP 22)
```
If your version is _higher_ than `1.10.3` that's _good_! 

2. Install Nerves on your **`localhost`**.
Follow the offical documentation
to install it on your operating system:
https://hexdocs.pm/nerves/installation.html

e.g on Mac you need install a few build utilities
in order to compile your IoT App for the target device.
Using [Homebrew](https://brew.sh) run the following commands:

```sh
brew update
brew install fwup squashfs coreutils xz pkg-config
```

Once you have all the build tools installed,
run the following command to install `nerves_bootstrap`:
```
mix archive.install hex nerves_bootstrap
```
<!-- return to this if/when needed during deployment
3. Ensure you have **SSH Keys**.
   Nerves expects you to have SSH keys setup under `$HOME/.ssh`. 
   This is so we can remotely debug and upload firmware later. 
   If you don't have ssh keys setup, 
   run `ssh-keygen` and accept all the defaults.
-->
3. **Equipment needed**:
   we're using a 
   [**Raspberry Pi Zero**](https://www.raspberrypi.org/products/raspberry-pi-zero)
   and an _external_ LED. 
   This is a *deliberate* choice to show
   how the entire system fits together.
   Any Recent Raspberry Pi will work,
   we use the Pi Zero because it's the _cheapest_ one.

   > If you want to use the _internal_ LED on your Raspberry Pi,
   see the example on the Nerve's platform `Blinky` project: 
   https://github.com/nerves-project/nerves_examples/tree/main/blinky

   * Raspberry Pi - any version will work.
   * 1 LED - Something like one of these form Pi Hut: 
   https://thepihut.com/products/ultimate-5mm-led-kit
   * 1 330 ohm resistor - without the resistor your LED will burn out!
   * a breadboard
   * Two jumper wires
   
   The resistor is **very** important
   as the LED has almost no internal resistance 
   it could seriously damage your Raspberry Pi 
   as it will try and draw an unlimited amout of current.


### 1. Wiring Up

> **Note**: this section uses content from the Pi Hut, found at: 
https://thepihut.com/blogs/raspberry-pi-tutorials/27968772-turning-on-an-led-with-your-raspberry-pis-gpio-pins

We need to connect the led to the Raspberry Pi. 
Your Pi should have a load of pins on the side that looks like this:

![Raspberry Pi Pin Layout](https://cdn.shopify.com/s/files/1/0176/3274/files/Pins_Only_grande.png?2408547127755526599 "Image credit: Pi Hut")

To power the LED we will need to use a General Purpose Input/Output (GPIO) pin,
which when turned *on* outputs 3.3v 
and a ground pin which is at a constant 0v. 
For this guide, we'll use **Pin 18**.

Wire everything up like this:

![Wiring Layout](https://cdn.shopify.com/s/files/1/0176/3274/files/LEDs-BB400-1LED_bb_grande.png?6398700510979146820)

The "black" wire needs to be plugged into a ground pin, and the "orange wire" needs to be pluged into a GPIO pin (Ideally 18 for the ease of following this tutorial).

*TODO: Explain more about breadboards*

### 2. Creating a nerves application.

If you managed to install Nerves correctly in Step #0, 
you should be able to create a new Nerves application by running:

```sh
mix nerves.new smart_led
```

where **`smart_led`** is the name of our project.

Say yes when it asks to install required dependencies.

Lets break down the message returned by the project generator:

```
Your Nerves project was created successfully.
```
Yay! - If you get any errors here, ready them carefully, it will normally say what went wrong. If your still unsure, create an issue.

```
You should now pick a target. See https://hexdocs.pm/nerves/targets.html#content
for supported targets. If your target is on the list, set `MIX_TARGET`
to its tag name:

For example, for the Raspberry Pi 3 you can either
  $ export MIX_TARGET=rpi3
Or prefix `mix` commands like the following:
  $ MIX_TARGET=rpi3 mix firmware

If you will be using a custom system, update the `mix.exs`
dependencies to point to desired system's package.
```
Whats a target? The nerves documentation says:
>The platform for which your firmware is built (for example, Raspberry Pi, Raspberry Pi 2, or Beaglebone Black).

From this we can see that we need to specify a target 
to develop our application for. 
We want to be able to develop on our current computer, 
but run the finished code on our deployment target. 
Nerves has a solution for this. 
Our current, and default target is `host`, or our current computer.
This means we can easily test and run our nerves code in development. 

Open a new terminal tab. 
We'll use two terminal tabs, 
one with our `MIX_TARGET` var set to `host` to develop with, 
and one with our `MIX_TARGET` set to the 
device your going to deploy on. 
Lets visit the link that was suggested to us, 
https://hexdocs.pm/nerves/targets.html#content, 
and pick our target tag.

Find your device tag, this will look something like `rpi3` 
and lets use it to setup your new terminal tab.

```
export MIX_TARGET=<Your tag>
```

In our case we are using a Raspberry Pi Zero (Zero W to be precise),
so our `export` is:

```
export MIX_TARGET=rpi0
```


Now download the dependencies and build a firmware archive:

```
cd smart_led
mix deps.get
```

You should see output similar to the following:

```
Nerves environment
  MIX_TARGET:   rpi0
  MIX_ENV:      dev

Resolving Nerves artifacts...
  Resolving nerves_system_rpi0
  => Trying https://github.com/nerves-project/nerves_system_rpi0/releases/download/v1.12.1/nerves_system_rpi0-portable-1.12.1-0D8B7B0.tar.gz
|==================================================| 100% (141 / 141) MB
  => Success
  Resolving nerves_toolchain_armv6_rpi_linux_gnueabi
  => Trying https://github.com/nerves-project/toolchains/releases/download/v1.3.2/nerves_toolchain_armv6_rpi_linux_gnueabi-darwin_x86_64-1.3.2-CDA7B05.tar.xz
|==================================================| 100% (55 / 55) MB
  => Success
```

This tells us that the nerves toolchain for compiling for the Raspberry Pi 
downloaded successfully.


Next run:
```
mix firmware
```

If your target boots up using an SDCard (like the Raspberry Pi),
then insert an SDCard into a reader on your computer and run:

```
mix firmware.burn
```

Plug the SDCard into the target and power it up. See target documentation
above for more information and other targets.
```
If you want, you can run these commands from the generator in your new terminal window to confirm everyting works. We'll do this in a few steps time anyway


### 3. Simple blinking LED module

Open up the project folder we just created in your favourite code editor, 
in our case we ran:

```
code smart_led/ # open the project in VSCodium
```

In this folder you'll find the standard Elixir/Mix project layout. 
We'll leave the `config` folder for now as 
Nerves ships with some sane defaults. 
In the next chapter we'll look at adding `target` specific configs and features.

If you look in the `lib/smart_led` folder and open `application.ex` you'll find a supervisor tree that looks a little different than usual. Take the time
to read through the comments in this file. There are 3 lists defined in this file, one for Children for all targets,
one for Children for the host, and one for any other targets. This lets us fine tune how are processes run.

We want to be able to blink an LED, this won't work on the host computer so we only want to run it on the target. To
do this lets define a child process in the last function for our targets like so:
```elixir
  def children(_target) do
    [
      SmartLed.LedController
    ]
  end

```
By doing this the BEAM will start and supervise the `SmartLed.LedController` module when our application starts.
If it crashes, it will just get restarted and we won't have to worry.

If we run the application now it won't work as we haven't defined the module `SmartLed.LedController` yet, so lets do that now.

Create a new file called `led_controller.ex` in the same file as the as the application module we just looked at. In
in this file we are going to define a `GenServer` that will control our lights. This will help us call our lights 
from another process later.

Lets start by defining our standard Elixir boilerplate by creating our module. We'll also `use GenServer` to import
all of the required GenServer functions and define some good defaults.

```elixir
defmodule SmartLed.LedController do
  use GenServer
end
```

Those of you with well setup errors will get a linting error now as `GenServer` expects `init/1` to be defined, 
so lets do that now. 
```elixir
  def init(_opts) do
    send(self(), :blink)
    {:ok, opts}
  end
```
`init/1` takes one argument that contains options passed to it by the function that starts the `GenServer`. In the
function body we send a `:blink` message to ourselves. This will get queued up in our `GenServer`'s mailbox and 
processed once we're fully set up. We then finish setting up our `GenServer` by telling returning a tuple with the 
`:ok` message and our `GenServer`'s state, which in this case we'll just set to opts in case we need to access these
later.

Our GenServer then needs to be able to handle the `:blink` message. `GenServer`s handle incoming messages through
the `handle_info/2` callback so lets create one for our blink message

```elixir
  def handle_info(:blink, state) do
    Process.send_after(self(), :blink, 2000)
    blink_led()

    {:noreply, state}
  end
```
Lets break this down line by line:

* We first pattern match on the `:blink` message in our function declaration
* We then send ourselves a blink message again, but schedule it for 2000ms time.
* We call a (as yet undeclared) function to blink our led
* We return control to the `GenSever`, saying we don't want to reply and with our state

To Blink the LED we need to a library to call to run the barebones code of telling the Raspberry Pi to open and 
and close the GPIO Pin. Luckily, Elixir Circuits will do this for us. Add `{:circuits_gpio, "~> 0.4"}` to
your mix deps in `~mix.exs` like so

```elixir
defp deps do
    [
      ...
      {:circuits_gpio, "~> 0.4"},
      ...
    ]
```
We don't need to worry about only using this on specific targets as Circuits automatically works out on what
type of device its running on. Lets go back to our code and implement our LED Blinking.

We need to define `blink_led/0`:

```elixir
  alias Circuits.GPIO

  defp blink_led() do
    {:ok, gpio} = GPIO.open(18, :output)
    GPIO.write(gpio, 1)
    :timer.sleep(100)
    GPIO.write(gpio, 0)
    GPIO.close(gpio)
  end
```
Once again, lets break this down line by line.
* We first create a reference to a GPIO pin so we can access it later, if you used a pin other that 18 earlier, feel
  free to change it
* We then write "1" to this pin, effectively turning it on
* We then pause execution for 100ms, leavingt the led light on.
* We then write "0" to the pin, effectievly turning it off.
* Finally we close the reference to the pin, letting the BEAM know we can safely derefence this pin.

Finally, we need to write one more function that will connect our new `GenServer` to the application supervisor,
if you've written `GenServers` before this will look very familiar

```elixir
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
```

This starts the GenServer process with the current module, gives it the options from the supervisor and names the new
process the same as the module.

### 4. Deploying your application.

**In the terminal where you set your `MIX_TARGET` environment variables**, we can build and deploy the firmware.

*Lost it? just run `export MIX_TARGET=<Your tag>` again*

First of all, lets download the dependencies for the target

```
mix deps.get
```
This will take a while as it will download the firmware needed for your device.

Then plug in an SD card and run:

```
mix firmware.burn
```

It will ask you to confirm the correct SD card, double check this as you could overwrite something important!

Plug the card into the Pi, turn it on and within 30 seconds it should start to blink!

# TODO: Add networking and GUI