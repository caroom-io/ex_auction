defmodule ExAuction.Auction do
  defstruct [
    :currency,
    :end_time,
    :item_id,
    :min_bid,
    :name,
    :start_time,
    :status,
    :step,
    :type,
    :finalize_with
  ]

  @type t :: %__MODULE__{
          currency: :string,
          end_time: DateTime.t(),
          item_id: :string,
          min_bid: :decimal,
          name: :string,
          start_time: DateTime.t(),
          step: :decimal,
          status: :active | :suspended | :finished,
          type: :string,
          finalize_with: any()
        }
  defmodule Bid do
    defstruct [:value, :user_id]

    @type t :: %__MODULE__{
            value: :integer,
            user_id: :string
          }

    defmodule Error do
      defstruct [:code, :message]

      def too_low(message \\ ""), do: %__MODULE__{code: :bid_too_low, message: message}

      def bid_closed(message \\ ""), do: %__MODULE__{code: :bid_closed, message: message}
    end
  end
end
