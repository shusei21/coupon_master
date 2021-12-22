class Item < ApplicationRecord
	has_one :reserve
	belongs_to :coupon
end
