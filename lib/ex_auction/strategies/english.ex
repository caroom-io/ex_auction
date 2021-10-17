defmodule ExAuction.Strategies.English do
  @behaviour ExAuction.Behaviour

  @impl true
  def place_bid(%ExAuction.Auction{step: step}, %ExAuction.Auction.Bid{value: value} = new_bid) when is_number(value) do
    current_highest_bid = 20 # Find current highest bid
    next_allowed_bid = current_highest_bid + step || 5

    if value > next_allowed_bid do
      # Insert the new bid in registy?
      {:ok, new_bid}
    else
      # Update winning bid

      # Q: How do we persist bid
      {:error, ExAuction.Auction.Bid.TooLow.new("Specified bid is too low, value must be larger than #{next_allowed_bid}")}
    end
  end

  @impl true
  def pause(%ExAuction.Auction{} = auction) do
    # We should update this auction in the registry right?
    auction = Map.update(auction, :status, :suspended, fn _ -> :suspended end)

    {:ok, auction}
  end
end
