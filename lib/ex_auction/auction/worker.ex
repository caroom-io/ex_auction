defmodule ExAuction.Auction.Worker do
  use GenServer
  require Logger

  alias ExAuction.Auction
  @log_tag "[AuctionWorker]"
  @strategies [english: ExAuction.Strategies.English]

  defmodule State do
    defstruct auction: nil, bids: []
  end

  @timeout :timer.seconds(5)

  def start_link(%ExAuction.Auction{finalize_with: final_call} = auction)
      when is_function(final_call, 1) do
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

    {:ok, state, {:continue, auction}}
  end

  def handle_continue(%Auction{start_time: st, end_time: et}, state) do
    close_time = DateTime.diff(et, st, :millisecond)
    Process.send_after(self(), :close_auction, close_time)

    Logger.info("#{@log_tag} auction will be closed in #{close_time}ms")

    {:noreply, state}
  end

  def handle_call(
        {:place_bid, bid},
        _from,
        %__MODULE__.State{auction: %Auction{status: :active}, bids: bids} = state
      ) do
    case do_place_bid(state, bid) do
      {:ok, %Auction.Bid{} = last_bid} = result ->
        # sorting the bids in :desc order
        bids = Enum.sort([last_bid | bids], &(&1.value > &2.value))
        state = %__MODULE__.State{state | bids: [last_bid | bids]}
        {:reply, result, state, @timeout}

      error ->
        {:reply, error, state}
    end
  end

  def handle_info(
        :close_auction,
        %__MODULE__.State{auction: %Auction{finalize_with: final_func} = auction, bids: bids} =
          state
      ) do
    Logger.info("#{@log_tag} closing auction #{state.auction.name}")
    auction = %Auction{auction | status: :finished}

    # TODO determine the winning bid through the actual strategy adapater
    # Assuming we are in english strategy, taking the head bid
    final_func.({auction, hd(bids)})

    {:stop, :closing_auction, state}
  end

  def terminate(reason, _state) do
    Logger.info("#{@log_tag} terminating due to #{reason}")
    :ok
  end

  defp whereis(auction) do
    case :global.whereis_name(%Auction{auction | status: nil}) do
      :undefined -> nil
      pid -> pid
    end
  end

  defp register_process(pid, auction) do
    auction = %Auction{auction | status: nil}

    case :global.register_name(auction, pid) do
      :yes ->
        {:ok, pid}

      :no ->
        {:error, {:already_started, pid}}
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
