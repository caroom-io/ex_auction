defmodule ExAuction.Behaviour do
  @type auction :: ExAuction.Auction.t()
  @type bid :: ExAuction.Auction.Bid.t()

  # @callback start(auction()) :: {:ok, auction()} | {:error, any()}
  @callback pause(auction()) :: {:ok, auction()} | {:error, any()}
  @callback place_bid(auction(), bid()) :: {:ok, bid()}
end
