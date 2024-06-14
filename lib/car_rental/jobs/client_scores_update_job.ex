defmodule CarRental.Jobs.ClientScoresUpdateJob do
  use GenServer

  @week_in_milliseconds 604_800 * 1000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(state) do
    schedule_next_run()
    {:ok, state}
  end

  def handle_info(:weekly_scores_update, state) do
    CarRental.update_clients_trust_scores()
    schedule_next_run()
    {:noreply, state}
  end

  defp schedule_next_run do
    Process.send_after(self(), :weekly_scores_update, @week_in_milliseconds)
  end
end
