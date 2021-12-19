defmodule ExAuction do
  require Logger
  alias ExAuction.Auction.Supervisor
  @log_tag "[ExAuction]"

  @moduledoc """
  Public interface functions for Auctions
  """

  @doc """
  Place bid.

  ## Examples

      iex> ExAuction.place_bid()
      {:ok, %ExAuction.Auction.Bid{}}

  """

  defdelegate place_bid(auction, bid), to: ExAuction.Auction.Worker

  @doc """
  Start an auction.

  ## Examples

      iex> ExAuction.start()
      {:ok, %ExAuction.Auction{}}

  """
  @spec start(ExAuction.Auction.t()) ::
          {:ok, ExAuction.Auction.t()} | {:error, :alread_started} | {:error, :bad_argument}
  def start(%ExAuction.Auction{name: name} = auction) do
    auction
    |> Supervisor.start_auction()
    |> case do
      {:ok, _pid} ->
        Logger.info("#{@log_tag} started #{name} successfully")
        {:ok, %ExAuction.Auction{auction | status: :started}}

      {:error, {:already_started, _pid}} ->
        Logger.warn("#{@log_tag} attempted to start a running auction - #{name}")
        {:error, :already_started}

      {:error, reason} ->
        Logger.error("#{@log_tag} failure on starting auction, reason #{inspect(reason)}")
        {:error, :bad_argument}
    end
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
