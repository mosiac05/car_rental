defmodule CarRental do
  require Logger
  alias CarRental.Clients
  alias CarRental.Clients.Params, as: ClientParams
  alias CarRental.TrustScore
  alias CarRental.TrustScore.Params, as: TrustScoreParams

  @rate_limit 10
  @chunk_size 100
  @minute_in_milliseconds 60_000

  @moduledoc """
  Documentation for `CarRental`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> CarRental.hello()
      :world

  """
  def hello do
    :world
  end

  @doc """
  Updates the scores of all clients.

  ## Examples

      iex> CarRental.update_clients_trust_scores()
      :ok
  """
  @spec update_clients_trust_scores() :: :ok | :error
  def update_clients_trust_scores do
    get_clients()
    |> Stream.map(fn client ->
      %TrustScoreParams.ClientParams{
        client_id: client.id,
        age: client.age,
        license_number: client.license_number,
        rentals_count: length(client.rental_history)
      }
    end)
    |> Enum.chunk_every(@chunk_size)
    |> process_chunks(%{requests_made: 0, start_time: current_time()})

    Logger.info("Successfully Updated Clients Scores At: #{NaiveDateTime.utc_now()}")
    :ok
  rescue
    _ ->
      Logger.error("Failed To Update Clients Scores At: #{NaiveDateTime.utc_now()}")
      :error
  end

  defp get_clients do
    case Clients.list_clients() do
      {:ok, clients} -> clients
      _ -> []
    end
  end

  defp process_chunks([], _state), do: :ok

  defp process_chunks(
         [chunk | rest],
         %{requests_made: requests_made, start_time: start_time} = state
       ) do
    if requests_made >= @rate_limit and time_since(start_time) < @minute_in_milliseconds do
      :timer.sleep(@minute_in_milliseconds - time_since(start_time))
      updated_state = %{requests_made: 0, start_time: current_time()}
      process_chunks([chunk | rest], updated_state)
    else
      update_trust_scores(chunk)
      updated_state = %{requests_made: requests_made + 1, start_time: state.start_time}
      process_chunks(rest, updated_state)
    end
  end

  defp update_trust_scores(clients) do
    trust_scores =
      %TrustScoreParams{clients: clients}
      |> TrustScore.calculate_score()
      |> Enum.map(&%ClientParams{score: &1.score, client_id: &1.id})

    Task.async(fn -> Clients.save_score_for_client(trust_scores) end)
    |> Task.await()
  rescue
    error ->
      Logger.error("Error updating trust scores: #{inspect(error)}")
  end

  defp current_time, do: :os.system_time(:millisecond)

  defp time_since(start_time) do
    current_time() - start_time
  end
end
