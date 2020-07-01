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
    Process.send_after(self(), :blink, 2000)
    blink_led()

    {:noreply, state}
  end

  defp blink_led() do
    {:ok, gpio} = GPIO.open(18, :output)
    GPIO.write(gpio, 1)
    :timer.sleep(1000)
    GPIO.write(gpio, 0)
    GPIO.close(gpio)
  end
end
