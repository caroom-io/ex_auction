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

  def handle_info(:timeout, auction) do
    IO.puts("I am alive")
    {:noreply, auction, @timeout}
  end
end
