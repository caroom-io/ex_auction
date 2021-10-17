defmodule ExAuction.AuctionApi do
  @type auction()
  @type bid()
  @callback start(auction()) :: auction()
  @callback pause(auction()) :: auction()
  @callback place_bid(auction(), integer()) :: {:ok, bid()}
end
