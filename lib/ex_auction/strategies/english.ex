defmodule ExAuction.Strategies.English do
  alias ExAuction.Auction.Worker.State
  alias ExAuction.Auction.Bid.Error
  @behaviour ExAuction.Behaviour

  @impl true
  def allow_bid?(
        %State{auction: %ExAuction.Auction{step: step}, bids: bids},
        %ExAuction.Auction.Bid{value: value} = bid
      )
      when is_number(value) do
    next_bid_limit =
      case bids do
        # May be step is nullable
        [%_{value: highest_bid} | _bids] ->
          highest_bid + step || 0

        _ ->
          step || 0
      end

    unless(value < next_bid_limit) do
      {:ok, bid}
    else
      {:error,
       Error.too_low("Specified bid is too low, value must be larger than #{next_bid_limit}")}
    end
  end

  @impl true
  def winning_bid(%State{bids: bids}) do
    # Since all bids in the state are already sorted in descending order, we are safe to return the highest bid
    [winning_bid | _others] = bids

    {:ok, winning_bid}
  end

  def winning_bid(_), do: {:error, :bad_argument}
end
