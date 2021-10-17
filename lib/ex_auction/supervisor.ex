defmodule ExAuction.Supervisor do
  use DynamicSupervisor

  def start_auction(%ExAuction.Auction{} = auction) do
    {:ok, _pid} = ExAuction.Worker.start_link(auction)
  end

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
