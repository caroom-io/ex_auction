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
    :winning_bid
  ]

  @type t :: %__MODULE__{
          currency: :string,
          end_time: :integer,
          item_id: :string,
          min_bid: :decimal,
          name: :string,
          start_time: :integer,
          step: :decimal,
          status: :started | :suspended | :finished,
          type: :string,
          winning_bid: :string
        }
  defmodule Bid do
    defstruct [:value, :user_id]

    @type t :: %__MODULE__{
            value: :integer,
            user_id: :string
          }

    defmodule Errors do
      defmodule TooLow do
        defstruct [:code, :message]

        def new(message) do
          %__MODULE__{
            code: :bid_too_low,
            message: message
          }
        end
      end
    end
  end
end
