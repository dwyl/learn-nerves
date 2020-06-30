defmodule SmartLedTest do
  use ExUnit.Case
  doctest SmartLed

  test "greets the world" do
    assert SmartLed.hello() == :world
  end
end
