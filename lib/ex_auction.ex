defmodule ExAuction do
  require Logger
  alias ExAuction.Auction
  alias ExAuction.Auction.Supervisor
  @log_tag "[ExAuction]"

  @moduledoc """
  Public interface functions for Auctions
  """

  @doc """
  Auction state.

  ## Examples

      iex> ExAuction.get_state(t())
      {:ok, %ExAuction.Auction{}} | {:error, :auction_not_found}

  """

  @spec state(ExAuction.Auction.t()) ::
          {:ok, ExAuction.Auction.Worker.State.t()} | {:error, :auction_not_found}
  defdelegate state(auction), to: ExAuction.Auction.Worker, as: :get_state

  @doc """
  Stops a running auction

  ## Examples

      iex> ExAuction.stop(%ExAuction.Auction{})
      :ok

  """
  @spec stop(ExAuction.Auction.t()) ::
          :ok | {:error, :argument_error} | {:error, :auction_not_found}
  def stop(%ExAuction.Auction{} = auction), do: ExAuction.Auction.Worker.halt(auction)
  def stop(_), do: {:error, :argument_error}

  @doc """
  Place bid.

  ## Examples

      iex> ExAuction.place_bid(%ExAuction.Auction{}, %ExAuction.Auction.Bid{})
      {:ok, %ExAuction.Auction.Bid{}}

  """

  @spec place_bid(ExAuction.Auction.t(), ExAuction.Auction.Bid.t()) ::
          {:ok, ExAuction.Auction.Bid.t()}
          | {:error, ExAuction.Auction.Bid.Error.t()}
          | {:error, :auction_not_found}
          | {:error, :argument_error}
  def place_bid(%Auction{} = auction, %Auction.Bid{user_id: user, value: value} = bid)
      when is_binary(user) and is_integer(value) do
    ExAuction.Auction.Worker.bid(auction, bid)
  end

  def place_bid(_, _), do: {:error, :argument_error}

  @doc """
  Start an auction.

  ## Examples

      iex> ExAuction.start(%ExAuction.Auction{})
      {:ok, %ExAuction.Auction{}}

  """
  @spec start(ExAuction.Auction.t()) ::
          {:ok, ExAuction.Auction.t()}
          | {:error, :alread_started}
          | {:error, :bad_argument}
          | {:error, :final_call_notfound}
  def start(%ExAuction.Auction{name: name, finalize_with: final_call} = auction)
      when is_function(final_call, 1) do
    auction
    |> Supervisor.start_auction()
    |> case do
      {:ok, pid} ->
        Logger.info("#{@log_tag} started #{name} successfully")
        {:ok, %ExAuction.Auction{auction | status: :started, pid: pid}}

      {:error, {:already_started, _pid}} ->
        Logger.warn("#{@log_tag} attempted to start a running auction - #{name}")
        {:error, :already_started}

      {:error, reason} ->
        Logger.error("#{@log_tag} failure on starting auction, reason #{inspect(reason)}")
        {:error, :bad_argument}
    end
  end

  def start(_), do: {:error, :final_call_notfound}
end
