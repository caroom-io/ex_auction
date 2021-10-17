defmodule ExAuction.Worker do
  use GenServer
  alias ExAuction.Auction
  @strategies [english: ExAuction.Strategies.English]

  defmodule State do
    defstruct auction: nil, bids: []
  end

  @timeout :timer.seconds(5)

  def place_bid(%Auction{} = auction, %Auction.Bid{} = bid) do
    with [{pid, _}] <- Registry.lookup(ExAuction.Registry, auction) do
      GenServer.call(pid, {:place_bid, bid})
    else
      _ ->
        {:error, :no_auction}
    end
  end

  def start_link(%ExAuction.Auction{} = auction) do
    GenServer.start_link(__MODULE__, auction,
      name: {:via, Registry, {ExAuction.Registry, auction}}
    )
  end

  def init(auction) do
    state = %__MODULE__.State{auction: %Auction{auction | status: :active}}

    {:ok, state, @timeout}
  end

  def handle_call(
        {:place_bid, bid},
        _from,
        %__MODULE__.State{auction: %Auction{status: :active}, bids: bids} = state
      ) do
    case do_place_bid(state, bid) do
      {:ok, %Auction.Bid{} = last_bid} = result ->
        state = %__MODULE__.State{bids: [last_bid | bids]}
        {:reply, result, state, @timeout}

      error ->
        {:reply, error, state, @timeout}
    end
  end

  def handle_info(:timeout, %__MODULE__.State{auction: %Auction{status: :active}} = state) do
    IO.puts("I am alive")
    # ... do some businesss
    {:noreply, state, @timeout}
  end

  def handle_info(:timeout, %__MODULE__.State{auction: %Auction{status: :finished}} = state) do
    IO.puts("I am alive")
    # ... do some businesss
    {:noreply, state, @timeout}
  end

  Enum.each(@strategies, fn {strategy, strategy_module} ->
    defp do_place_bid(
           %_{auction: %Auction{type: unquote(strategy)} = auction},
           %Auction.Bid{} = bid
         ) do
      apply(unquote(strategy_module), :place_bid, [auction, bid])
    end
  end)

  defp do_place_bid(_, _), do: {:error, :bad_argument}
end

# my_auction = %ExAuction.Auction{name: "Moller Auto Audi R8"}
# ExAuction.start(my_auction)
# ExAuction.place_bid(my_auction, %ExAuction.Auction.Bid{user_id: "adio", value: 5000})
