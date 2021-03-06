defmodule ExAuctionTest do
  use ExUnit.Case
  import Mock
  # doctest ExAuction

  alias ExAuction.Auction.Bid.Error

  defmodule FinalCallee do
    def finalize_auction(state_tuple) do
      IO.inspect(state_tuple, label: "Received the state tuple")
    end
  end

  defmodule FinalCalleeB do
    def finalize_auction(state_tuple) do
      IO.inspect(state_tuple, label: "Received the state tuple")
    end
  end

  setup %{} do
    {:ok, auction} = gen_auction() |> ExAuction.start()

    %{auction: auction}
  end

  test "start auction with no final call" do
    assert {:error, :bad_argument} =
             %ExAuction.Auction{gen_auction() | callbacks: %{finalize_with: nil}}
             |> ExAuction.start()
  end

  test "place bid", %{auction: auction} do
    bid1 = %ExAuction.Auction.Bid{value: 10000, user_id: gen_name()}
    assert {:ok, %ExAuction.Auction.Bid{}} = ExAuction.place_bid(auction, bid1)

    bid2 = %ExAuction.Auction.Bid{value: 500, user_id: gen_name()}
    assert {:error, %Error{code: :bid_too_low}} = ExAuction.place_bid(auction, bid2)
  end

  test_with_mock "close of auction - ensure final call", %{}, FinalCallee, [],
    finalize_auction: fn _arg -> :ok end do
    {:ok, %_{pid: pid} = auction} =
      %ExAuction.Auction{
        gen_auction()
        | callbacks: %{finalize_with: &FinalCallee.finalize_auction/1}
      }
      |> ExAuction.start()

    bid1 = %ExAuction.Auction.Bid{value: 10000, user_id: gen_name()}
    bid2 = %ExAuction.Auction.Bid{value: 20000, user_id: gen_name()}
    assert {:ok, %ExAuction.Auction.Bid{}} = ExAuction.place_bid(auction, bid1)
    assert {:ok, %ExAuction.Auction.Bid{}} = ExAuction.place_bid(auction, bid2)

    send(pid, :close_auction)
    :timer.sleep(1000)
    final_auction = %{auction | status: :finished, pid: nil}
    assert_called(FinalCallee.finalize_auction({final_auction, bid2}))
  end

  test "restart auction with exisiting offers from previous session" do
    bid1 = %ExAuction.Auction.Bid{value: 10000, user_id: gen_name()}
    bid2 = %ExAuction.Auction.Bid{value: 20000, user_id: gen_name()}
    bids = [bid2, bid1]

    auction = %ExAuction.Auction{
      gen_auction()
      | callbacks: %{finalize_with: &FinalCallee.finalize_auction/1}
    }

    {:ok, %_{pid: _pid} = auction} = ExAuction.start(auction, bids)

    assert %ExAuction.Auction.Worker.State{auction: %ExAuction.Auction{}, bids: bids_in_state} =
             ExAuction.state(auction)

    assert 2 = length(bids_in_state)
  end

  test_with_mock "Ensure proper completion if auction end_time has passed", %{}, FinalCalleeB, [],
    finalize_auction: fn _arg -> :ok end do
    now = DateTime.utc_now()
    start_time = DateTime.add(now, -600)
    end_time = DateTime.add(now, -300)

    bid1 = %ExAuction.Auction.Bid{value: 10000, user_id: gen_name()}
    bid2 = %ExAuction.Auction.Bid{value: 20000, user_id: gen_name()}
    bids = [bid2, bid1]

    auction = %ExAuction.Auction{
      gen_auction()
      | callbacks: %{finalize_with: &FinalCalleeB.finalize_auction/1},
        start_time: start_time,
        end_time: end_time
    }

    {:ok, %_{pid: _pid} = auction} = ExAuction.start(auction, bids)

    :timer.sleep(10)
    final_auction = %{auction | status: :finished, pid: nil}
    assert_called(FinalCalleeB.finalize_auction({final_auction, bid2}))
  end

  test "auction suspension", %{auction: %_{pid: auction_pid} = auction} do
    assert :ok = ExAuction.stop(auction)
    :timer.sleep(500)

    refute Process.alive?(auction_pid)
  end

  test "get auction state", %{auction: %_{step: step} = auction} do
    for v <- 1..10 do
      bid1 = %ExAuction.Auction.Bid{value: v * step, user_id: gen_name()}
      assert {:ok, %ExAuction.Auction.Bid{}} = ExAuction.place_bid(auction, bid1)
    end

    assert %_{
             auction: %ExAuction.Auction{status: :active},
             bids: [%{value: v1}, %{value: v2}, _, _, _, _, _, _, _, _]
           } = ExAuction.state(auction)

    # cheking the sort order of bids
    assert v2 < v1
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
      type: :ENGLISH,
      callbacks: %{
        finalize_with: fn {_auction, winning_bid} ->
          IO.inspect(winning_bid, label: "Winning Bid")
        end
      }
    }
  end
end
