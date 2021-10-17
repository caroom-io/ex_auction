defmodule Auction do
  defstruct [
    :currency,
    :end_time,
    :item_id,
    :min_bid,
    :name,
    :start_time,
    :status,
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
          status: :string,
          type: :string,
          winning_bid: :string
        }
  defmodule Bid do
    defstruct [:value, :user_id]

    @type t :: %__MODULE__{
            value: :decimal,
            user_id: :string
          }
  end
end
