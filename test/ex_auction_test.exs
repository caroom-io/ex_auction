defmodule ExAuctionTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  # doctest ExAuction

  alias ExAuction.Auction.Bid.Error

  setup %{} do
    start_time = DateTime.utc_now()
    end_time = DateTime.add(start_time, 6)
    # end_time = DateTime.add(start_time, 3600)

    %{
      auction: %ExAuction.Auction{
        currency: "EUR",
        end_time: end_time,
        item_id: "some",
        min_bid: :integer,
        name: "My test autcion",
        start_time: start_time,
        step: 10000,
        type: :english,
        finalize_with: fn {auction, winning_bid} ->
          IO.inspect(winning_bid, label: "Winning Bid")
        end
      }
    }
  end

  test "start auction", %{auction: auction} do
    assert {:ok, %ExAuction.Auction{status: :started} = auction} = ExAuction.start(auction)
    # place bid
    bid1 = %ExAuction.Auction.Bid{value: 10000}
    assert {:ok, %ExAuction.Auction.Bid{}} = ExAuction.place_bid(auction, bid1)

    bid2 = %ExAuction.Auction.Bid{value: 500}
    assert {:error, %Error{code: :bid_too_low}} = ExAuction.place_bid(auction, bid2)

    assert capture_io(fn -> :timer.sleep(7000) end) |> IO.inspect(label: "Captured")
  end

  test "start auction with no final call" do
    assert true
  end
end
