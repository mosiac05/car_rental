defmodule CarRentalTest do
  use ExUnit.Case
  doctest CarRental

  test "greets the world" do
    assert CarRental.hello() == :world
  end

  test "updates scores of all clients" do
    assert :ok = CarRental.update_clients_trust_scores()
  end
end
