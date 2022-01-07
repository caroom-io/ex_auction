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
    :finalize_with,
    :pid
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
          finalize_with: any(),
          pid: pid()
        }
  defmodule Bid do
    defstruct [:id, :value, :user_id]

    @type t :: %__MODULE__{
            id: any(),
            value: :integer,
            user_id: any()
          }

    defmodule Error do
      defstruct [:code, :message]

      def too_low(message \\ ""), do: %__MODULE__{code: :bid_too_low, message: message}

      def bid_closed(message \\ ""), do: %__MODULE__{code: :bid_closed, message: message}
    end
  end
end
