defmodule ExAuctionTest do
  use ExUnit.Case
  # doctest ExAuction

  alias ExAuction.Auction.Bid.Errors

  setup %{} do
    %{
      auction: %ExAuction.Auction{
        currency: "EUR",
        end_time: 1_640_941_794,
        item_id: "some",
        min_bid: :integer,
        name: "My test autcion",
        start_time: 1_639_912_194,
        step: 10000,
        type: :english
      }
    }
  end

  test "start auction", %{auction: auction} do
    assert {:ok, %ExAuction.Auction{status: :started} = auction} = ExAuction.start(auction)
    # place bid
    bid1 = %ExAuction.Auction.Bid{value: 10000}
    assert {:ok, %ExAuction.Auction.Bid{}} = ExAuction.place_bid(auction, bid1)

    bid2 = %ExAuction.Auction.Bid{value: 500}
    assert {:error, %Errors.TooLow{code: :bid_too_low}} = ExAuction.place_bid(auction, bid2)
  end
end
