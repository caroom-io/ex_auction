defmodule ExAuctionTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  # doctest ExAuction

  alias ExAuction.Auction.Bid.Error

  setup %{} do
    {:ok, auction} = gen_auction() |> ExAuction.start()

    %{auction: auction}
  end

  test "place bid", %{auction: auction} do
    bid1 = %ExAuction.Auction.Bid{value: 10000, user_id: gen_name()}
    assert {:ok, %ExAuction.Auction.Bid{}} = ExAuction.place_bid(auction, bid1)

    bid2 = %ExAuction.Auction.Bid{value: 500, user_id: gen_name()}
    assert {:error, %Error{code: :bid_too_low}} = ExAuction.place_bid(auction, bid2)

    # assert capture_io(fn -> :timer.sleep(7000) end) |> IO.inspect(label: "Captured")
  end

  test "get auction state", %{auction: %_{step: step} = auction} do
    for v <- 1..10 do
      bid1 = %ExAuction.Auction.Bid{value: v * step, user_id: gen_name()}
      assert {:ok, %ExAuction.Auction.Bid{}} = ExAuction.place_bid(auction, bid1)
    end

    assert %_{
             auction: %ExAuction.Auction{status: :active},
             bids: [%{user_id: user_id, value: v1}, %{value: v2}, _, _, _, _, _, _, _, _]
           } = ExAuction.state(auction)

    # cheking the sort order of bids
    assert v2 < v1
  end

  test "start auction with no final call", %{auction: auction} do
    # assert true
  end

  def gen_name, do: :crypto.strong_rand_bytes(20) |> Base.encode64()
  def gen_auction do
    start_time = DateTime.utc_now()
    end_time = DateTime.add(start_time, 6)

    %ExAuction.Auction{
      currency: "EUR",
      end_time: end_time,
      item_id: "some",
      min_bid: :integer,
      name: gen_name(),
      start_time: start_time,
      step: 10000,
      type: :english,
      finalize_with: fn {auction, winning_bid} ->
        IO.inspect(winning_bid, label: "Winning Bid")
      end
    }
  end
end
