defmodule ExAuction.Auction.Worker do
  use GenServer
  alias ExAuction.Auction
  @strategies [english: ExAuction.Strategies.English]

  defmodule State do
    defstruct auction: nil, bids: []
  end

  @timeout :timer.seconds(5)

  def whereis(auction) do
    case :global.whereis_name(%Auction{auction | status: nil}) do
      :undefined -> nil
      pid -> pid
    end
  end

  def register_process(pid, auction) do
    auction = %Auction{auction | status: nil}

    case :global.register_name(auction, pid) do
      :yes -> {:ok, pid}
      :no -> {:error, {:already_started, pid}}
    end
  end

  def place_bid(%Auction{} = auction, %Auction.Bid{} = bid) do
    case whereis(auction) do
      pid when is_pid(pid) ->
        GenServer.call(pid, {:place_bid, bid})

      _ ->
        {:error, :no_auction}
    end
  end

  def start_link(%ExAuction.Auction{} = auction) do
    case whereis(auction) do
      nil ->
        {:ok, pid} = GenServer.start_link(__MODULE__, auction)
        register_process(pid, auction)

      pid ->
        {:error, {:already_started, pid}}
    end
  end

  def init(auction) do
    state = %__MODULE__.State{auction: %Auction{auction | status: :active}, bids: []}
    {:ok, state, @timeout}
  end

  def handle_call(
        {:place_bid, bid},
        _from,
        %__MODULE__.State{auction: %Auction{status: :active}, bids: bids} = state
      ) do
    case do_place_bid(state, bid) do
      {:ok, %Auction.Bid{} = last_bid} = result ->
        # TODO Arrange the bids descresing after accepting it.
        state = %__MODULE__.State{state | bids: [last_bid | bids]}
        {:reply, result, state, @timeout}

      error ->
        {:reply, error, state, @timeout}
    end
  end

  Enum.each(@strategies, fn {strategy, strategy_module} ->
    defp do_place_bid(
           %_{auction: %Auction{type: unquote(strategy)}} = state,
           %Auction.Bid{} = bid
         ) do
      apply(unquote(strategy_module), :allow_bid?, [state, bid])
    end
  end)

  defp do_place_bid(_, _), do: {:error, :bad_argument}
end
