defmodule ExAuction.Auction.Worker do
  use GenServer
  require Logger

  alias ExAuction.Auction
  @log_tag "[AuctionWorker]"
  @strategies [ENGLISH: ExAuction.Strategies.English]

  defmodule State do
    defstruct auction: nil, bids: []
  end

  @timeout :timer.seconds(5)

  def bid(%Auction{} = auction, %Auction.Bid{} = bid) do
    case whereis(auction.name) do
      pid when is_pid(pid) ->
        GenServer.call(pid, {:place_bid, bid})

      _ ->
        {:error, :auction_not_found}
    end
  end

  def get_state(%ExAuction.Auction{} = auction) do
    case whereis(auction.name) do
      nil ->
        {:error, :auction_not_found}

      pid ->
        GenServer.call(pid, :get_state)
    end
  end

  def halt(%ExAuction.Auction{} = auction) do
    case whereis(auction.name) do
      pid when is_pid(pid) ->
        GenServer.cast(pid, :halt)

      _ ->
        {:error, :auction_not_found}
    end
  end

  def start_link(%__MODULE__.State{auction: %ExAuction.Auction{} = auction} = auction_state) do
    case whereis(auction.name) do
      nil ->
        {:ok, pid} = GenServer.start_link(__MODULE__, auction_state)
        register_process(pid, auction.name)

      pid ->
        # TODO: We should check the state of the auction, if suspended, then we resume it
        {:error, {:already_started, pid}}
    end
  end

  def init(%__MODULE__.State{auction: auction, bids: init_state_bids}) do
    state = %__MODULE__.State{auction: %Auction{auction | status: :active}, bids: init_state_bids}

    {:ok, state, {:continue, auction}}
  end

  def handle_continue(%Auction{end_time: et}, state) do
    now = DateTime.utc_now()
    close_time = DateTime.diff(et, now, :millisecond)

    case close_time do
      time when time > 0 ->
        Logger.info("#{@log_tag} auction will be closed in #{close_time}ms")
        Process.send_after(self(), :close_auction, close_time)

      _ ->
        Logger.info(
          "#{@log_tag} auction will be closed right away because endtime is passed by #{
            close_time
          }ms"
        )

        Process.send(self(), :close_auction, [:nosuspend])
    end

    {:noreply, state}
  end

  def handle_cast(
        :halt,
        %__MODULE__.State{auction: %Auction{status: :active} = auction} = state
      ) do
    state = %__MODULE__.State{state | auction: %Auction{auction | status: :suspended}}

    Logger.info("#{@log_tag} suspending auction")

    {:stop, :normal, state}
  end

  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_call(
        {:place_bid, bid},
        _from,
        %__MODULE__.State{auction: %Auction{status: :active}, bids: bids} = state
      ) do
    case do_place_bid(state, bid) do
      {:ok, %Auction.Bid{} = last_bid} = result ->
        # TODO: Confirm why we need this sorting, it feels artificial
        # sorting the bids in :desc order
        state = %__MODULE__.State{
          state
          | bids: Enum.sort([last_bid | bids], &(&1.value > &2.value))
        }

        {:reply, result, state, @timeout}

      error ->
        {:reply, error, state}
    end
  end

  def handle_info(
        :close_auction,
        %__MODULE__.State{auction: %Auction{finalize_with: final_func} = auction} = state
      ) do
    Logger.info("#{@log_tag} closing auction #{state.auction.name}")
    auction = %Auction{auction | status: :finished}

    {:ok, winning_bid} = get_winning_bid(state)

    _ = final_func.({auction, winning_bid})

    state = %__MODULE__.State{state | auction: auction}

    {:stop, :normal, state}
  end

  def terminate(reason, _state) do
    Logger.info("#{@log_tag} terminating due to #{reason}")
    :ok
  end

  defp whereis(auction_name) do
    case :global.whereis_name(auction_name) do
      :undefined -> nil
      pid -> pid
    end
  end

  defp register_process(pid, auction_name) do
    case :global.register_name(auction_name, pid) do
      :yes ->
        {:ok, pid}

      :no ->
        {:error, {:already_started, pid}}
    end
  end

  Enum.each(@strategies, fn {strategy, strategy_module} ->
    defp do_place_bid(
           %_{auction: %Auction{type: unquote(strategy)}} = state,
           %Auction.Bid{} = bid
         ) do
      apply(unquote(strategy_module), :allow_bid?, [state, bid])
    end

    defp get_winning_bid(%_{auction: %Auction{type: unquote(strategy)}} = state) do
      apply(unquote(strategy_module), :winning_bid, [state])
    end
  end)

  defp do_place_bid(_, _), do: {:error, :bad_argument}
  defp get_winning_bid(_), do: {:error, :bad_argument}
end
