defmodule ExAuction do
  alias ExAuction.Auction
  @strategies [english: ExAuction.Strategies.English]
  @moduledoc """
  Public interface functions for Auctions
  """

  @doc """
  Place bid.

  ## Examples

      iex> ExAuction.place_bid()
      {:ok, %ExAuction.Auction.Bid{}}

  """
  Enum.each(@strategies, fn {strategy, strategy_module} ->
    def place_bid(%Auction{type: unquote(strategy)}, %Auction.Bid{} = bid) do
      apply(unquote(strategy_module), :place_bid, [bid])
    end
  end)

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
