defmodule State.Alert.ActivePeriod do
  @moduledoc """
  A flattened cache of the current alerts, for easier querying of active period
  """
  use Recordable, [:id, :start, :stop, :updated_at]
  alias Model.Alert

  @table __MODULE__

  def new(table \\ @table) do
    ^table = :ets.new(table, [:named_table, :duplicate_bag, {:read_concurrency, true}])
    :ok
  end

  def update(table \\ @table, alerts)

  def update(table, [_ | _] = alerts) do
    flattened = Enum.flat_map(alerts, &flatten/1)

    :ok = update(table, [])
    true = :ets.delete_all_objects(table)
    true = :ets.insert(table, flattened)
    :ok
  end

  def update(_table, []) do
    # ignore empty updates
    :ok
  end

  def size(table \\ @table) do
    State.Helpers.safe_ets_size(table)
  end

  def filter(table \\ @table, ids, dt)

  def filter(_table, [], _dt) do
    []
  end

  def filter(table, ids, %DateTime{} = dt) when is_list(ids) do
    unix = DateTime.to_unix(dt)

    query = [{:>=, unix, :"$1"}, {:<, unix, :"$2"}]

    selectors =
      for id <- ids do
        {
          {id, :"$1", :"$2"},
          query,
          [id]
        }
      end

    IO.inspect(selectors)
    :ets.select(table, selectors)
  end

  defp flatten(%Alert{active_period: []} = alert) do
    flatten(%{alert | active_period: [{nil, nil}]})
  end

  defp flatten(%Alert{id: id, active_period: active_period, updated_at: updated_at}) do
    for {start, stop} <- active_period do
      flatten_row(id, start, stop, updated_at)
    end
  end

  defp flatten_row(id, nil, nil, updated_at), do: {id, 0, :max, maybe_to_unix(updated_at)}

  defp flatten_row(id, nil, stop, updated_at),
    do: {id, 0, DateTime.to_unix(stop), maybe_to_unix(updated_at)}

  defp flatten_row(id, start, nil, updated_at),
    do: {id, DateTime.to_unix(start), :max, maybe_to_unix(updated_at)}

  defp flatten_row(id, start, stop, updated_at),
    do: {id, DateTime.to_unix(start), DateTime.to_unix(stop), maybe_to_unix(updated_at)}

  defp maybe_to_unix(nil), do: nil
  defp maybe_to_unix(dt), do: DateTime.to_unix(dt)
end
