defmodule ExAuction do
  alias ExAuction.Auction

  @moduledoc """
  Public interface functions for Auctions
  """

  @doc """
  Place bid.

  ## Examples

      iex> ExAuction.place_bid()
      {:ok, %ExAuction.Auction.Bid{}}

  """

  defdelegate place_bid(auction, bid), to: ExAuction.Worker

  @doc """
  Start an auction.

  ## Examples

      iex> ExAuction.start()
      {:ok, %ExAuction.Auction{}}

  """
  @spec start(ExAuction.Auction.t()) ::
          {:ok, ExAuction.Auction.t()} | {:error, :alread_started} | {:error, :bad_argument}
  def start(%ExAuction.Auction{} = auction) do
    ExAuction.Supervisor.start_auction(auction)
  end

  @doc """
  Pause an auction.

  ## Examples

      iex> ExAuction.pause()
      {:ok, %ExAuction.Auction{}}

  """
  def pause() do
    {:ok, %ExAuction.Auction{}}
  end
end
