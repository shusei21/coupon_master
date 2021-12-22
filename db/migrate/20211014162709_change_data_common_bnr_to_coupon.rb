class ChangeDataCommonBnrToCoupon < ActiveRecord::Migration[6.1]
  def change
  	change_column :coupons, :common_bnr, :string
  	change_column :coupons, :coupon_bnr, :string
  end
end
