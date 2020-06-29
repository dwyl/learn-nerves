<div align="center">

# Nerves LED Blinking tutorial

A complete tutorial of how to deploy a Nerves application on a Raspberry Pi
</div>

<br></br>

## Why?

Nerves is a simple to use IoT framework thats rock-solid thanks to it running on the BEAM (Erlang virtual machine). However, in order to start building
and working on systems its useful to have a knowledge of how the whole framework fits together and how it interacts with the wider Elixir ecosystem.

Although I have refered to Nerves as a framework, Nerves is better described as a **platform**, in that you write pure Elixir code and almost never
call Nerves functions. Nerves packages up your code and creates Linux firmware image that includes everything you need and nothing more. When the Raspberry
Pi has finished booting Nerves starts your Elixir application and its dependencies.

Nerves includes lots of features such as Over-The-Air firmware updates that means you can truly "fire and forget".

## What?

A simple step-by-step that will show you how to:
- **Create** a Nerves application from scratch
- **Add** a simple module to blink an LED
- **Deploy** your application on a Raspberry Pi
- **Tweaking** your application and redeploying Over-The-Air

*For simple Nerves applications, thats it! But (**Intermediate knowledge of Elixir recommended)** we can also add a web-based GUI by*:
- **Refractoring** the blinking LED control into a named `GenServer` that you can can call it from another BEAM Application.
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

1. #### Elixir needs to be installed on your **local machine**
   
   https://elixir-lang.org/install.html

2. #### Nerves needs to be installed.
   Nerves is a pain to configure on some systems, and needs specific versions of Erlang/OTP. The offical documentation is excellent, so I suggest you follow
   that here: https://hexdocs.pm/nerves/installation.html

3. #### Equipment needed
   We're going to be using a Raspberry Pi Zero and an external LED. This is a *deliberate* choice to help teach you how the entire system fits together.
   If you want to use the internal LED, I recommend looking at the Nerve's platform example `Blinky` project here: https://github.com/nerves-project/nerves_examples/tree/main/blinky

   * Raspberry Pi - any version will do. Ideally one with WiFi, but if not and you have a working ethernet connection thats fine.
   * LED. - Something like one of [these](https://thepihut.com/products/ultimate-5mm-led-kit) but any should do
   * 330 ohm resistor
   * A breadboard
   * Two jumper wires
   
   The resistor is **very** important,  as the LED has almost no internal resistance it could seriously damage your Raspberry Pi as it will try and draw
   an unlimited amout of current.

### 1. Wiring Up.

*(Uses content from the Pi Hut, found at https://thepihut.com/blogs/raspberry-pi-tutorials/27968772-turning-on-an-led-with-your-raspberry-pis-gpio-pins)*

We need to connect the led to the Raspberry Pi. You pi should have a load of pins on the side that looks like this:
![Raspberry Pi Pin Layout](https://cdn.shopify.com/s/files/1/0176/3274/files/Pins_Only_grande.png?2408547127755526599)
*Pi Hut*

We need to use a GPIO pin, which when turned *on* outputs 3.3v and a ground pin, which is at a constant 0v. For this guide, we'll use **Pin 18**

Wire everything up like this:

![Wiring Layout](https://cdn.shopify.com/s/files/1/0176/3274/files/LEDs-BB400-1LED_bb_grande.png?6398700510979146820)

The "black" wire needs to be plugged into a ground pin, and the "orange wire" needs to be pluged into a GPIO pin (Ideally 18 for the ease of following this tutorial).

*TODO: Explain more about breadboards*

### 3. Creating a nerves application.
