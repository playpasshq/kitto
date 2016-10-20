defmodule Kitto.Job do
  def start_link(job) do
    {:ok, spawn_link(Kitto.Job, :new, [job])}
  end

  def register(name, options, job) do
    import Kitto.Time

    opts = [interval: options[:every] |> mseconds,
            first_at: options[:first_at] |> mseconds]

    Kitto.Runner.register(name: name, job: job, options: opts)
  end

  def new(job) do
    case job[:options][:interval] do
      nil -> once(job)
      _   -> with_interval(job)
    end
  end

  defp with_interval(job) do
    first_at(job[:options][:first_at], job)

    receive do
    after
      job[:options][:interval] ->
        run job
        with_interval(put_in(job[:options][:first_at], false))
    end
  end

  defp run(job), do: Kitto.StatsServer.measure(job[:name], job[:job])

  defp once(job) do
    run job

    receive do
    end
  end

  defp first_at(false, _job), do: nil
  defp first_at(t, job) do
    if t, do: :timer.sleep(t)

    run job
  end
end
