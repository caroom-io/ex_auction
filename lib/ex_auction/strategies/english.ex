defmodule ExAuction.Strategies.English do
  alias ExAuction.Auction.Worker.State
  alias ExAuction.Auction.Bid.Errors
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
       Errors.TooLow.new("Specified bid is too low, value must be larger than #{next_bid_limit}")}
    end
  end

  @impl true
  def pause(%ExAuction.Auction{} = auction) do
    # We should update this auction in the registry right?
    auction = Map.update(auction, :status, :suspended, fn _ -> :suspended end)

    {:ok, auction}
  end
end
