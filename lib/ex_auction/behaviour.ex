defmodule ExAuction.Behaviour do
  @type auction_state :: ExAuction.Auction.Worker.State.t()
  @type auction :: ExAuction.Auction.t()
  @type bid :: ExAuction.Auction.Bid.t()

  @callback winning_bid(auction_state()) :: {:ok, bid()} | {:error, any()}
  @callback allow_bid?(auction_state(), bid()) :: {:ok, bid()} | {:error, any()}
end
