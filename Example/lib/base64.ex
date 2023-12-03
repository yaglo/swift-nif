defmodule Base64 do
  @on_load :load_nifs
  def load_nifs do
    :erlang.load_nif('./priv/native/libBase64', 0)
  end

  def encode(_string) do
    raise "NIF not loaded"
  end

  def decode(_string) do
    raise "NIF not loaded"
  end
end
