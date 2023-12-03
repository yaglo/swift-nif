defmodule ExampleTest do
  use ExUnit.Case

  test "encodes" do
    encoded_string = Base64.encode("Hello, World!")
    IO.puts("Encoded 'Hello, World!': #{encoded_string}")
    assert encoded_string == "SGVsbG8sIFdvcmxkIQ=="
  end

  test "decodes" do
    decoded_string = Base64.decode("SGVsbG8sIFdvcmxkIQ==")
    IO.puts("Decoded 'SGVsbG8sIFdvcmxkIQ==': #{decoded_string}")
    assert decoded_string == "Hello, World!"
  end
end
