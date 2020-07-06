defmodule SmartLed.LedController do
  use GenServer
  alias Circuits.GPIO

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    send(self(), :blink)
    {:ok, opts}
  end

  def handle_info(:blink, state) do
    delay = :rand.uniform(2000)
    Process.send_after(self(), :blink, 2 * delay)
    blink_led(delay)

    {:noreply, state}
  end

  defp blink_led(delay) do
    {:ok, gpio} = GPIO.open(18, :output)
    GPIO.write(gpio, 1)
    :timer.sleep(delay)
    GPIO.write(gpio, 0)
    GPIO.close(gpio)
  end
end
