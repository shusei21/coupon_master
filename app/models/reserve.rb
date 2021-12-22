class Reserve < ApplicationRecord
	belongs_to :item
	has_one    :coupon,  through: :item
end
