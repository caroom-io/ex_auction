defmodule ExAuction.Auction.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_auction(%ExAuction.Auction.Worker.State{} = auction_state) do
    DynamicSupervisor.start_child(__MODULE__, {ExAuction.Auction.Worker, auction_state})
  end

  def stop_auction(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
