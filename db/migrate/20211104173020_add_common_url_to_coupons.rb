class AddCommonUrlToCoupons < ActiveRecord::Migration[6.1]
  def change
    add_column :coupons, :common_url, :string
  end
end
