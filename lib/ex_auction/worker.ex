defmodule ExAuction.Worker do
  use GenServer

  @timeout :timer.seconds(5)

  def start_link(%ExAuction.Auction{} = auction) do
    GenServer.start_link(__MODULE__, auction,
      name: {:via, Registry, {ExAuction.Registry, auction}}
    )
  end
  
  def init(auction) do
    {:ok, auction, @timeout}
  end

  def handle_info(:timeout, %ExAuction.Auction{status: :active} = auction) do
    IO.puts("I am alive")
    # ... do some businesss
    {:noreply, auction, @timeout}
  end

  def handle_info(:timeout, %ExAuction.Auction{status: :finished} = auction) do
    # We have finished at this point, we need to gather and summarize state
    # Send back to the provided callback
    {:noreply, auction, @timeout}
  end
end
