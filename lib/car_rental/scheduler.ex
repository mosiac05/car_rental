defmodule CarRental.Scheduler do
  use Quantum, otp_app: :car_rental
  @env Mix.env()

  @impl true
  def init(config) do
    jobs = [
      weekly_scores_update_job(config)
    ]

    Keyword.update(config, :jobs, jobs, &(&1 ++ jobs))
  end

  @spec weekly_scores_update_job(Keyword.t()) :: Quantum.Job.t()
  defp weekly_scores_update_job(config) do
    Quantum.Job.new(config)
    |> Quantum.Job.set_timezone(:utc)
    |> Quantum.Job.set_name(:weekly_scores_update_job)
    |> Quantum.Job.set_overlap(false)
    |> Quantum.Job.set_schedule(Crontab.CronExpression.Parser.parse!("0 0 * * SUN"))
    |> Quantum.Job.set_task({CarRental, :update_clients_trust_scores, []})
    |> Quantum.Job.set_state(get_state(@env))
    |> Quantum.Job.set_run_strategy(%Quantum.RunStrategy.Local{})
  end

  defp get_state(:test), do: :inactive
  defp get_state(_), do: :active
end
