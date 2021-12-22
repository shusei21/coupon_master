class AddcouponCodeToItems < ActiveRecord::Migration[6.1]
  def change
  	add_column :items, :coupon_code, :string
  end
end
