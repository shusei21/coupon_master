class AddCouponToCoupons < ActiveRecord::Migration[6.1]
  def change
    add_column :coupons, :coupon_code, :string
    add_column :coupons, :coupon_url, :string
  end
end
