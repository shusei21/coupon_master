class ReservesController < ApplicationController
	def index
		@reserves = Reserve.where(user_id:current_user.id)
		items = @reserves.pluck(:item_id)

		@items = Item.where(id: items)
		coupons = @items.pluck(:coupon_id)
		@coupons = Coupon.where(id: coupons)

		@reserves_ = Coupon.includes(:items).includes(:reserve)
		@reserves__ = Reserve.where(user_id:current_user.id).includes(:item).includes(:coupon)
	end
end
