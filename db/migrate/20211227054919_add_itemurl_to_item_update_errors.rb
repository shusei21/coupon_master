class AddItemurlToItemUpdateErrors < ActiveRecord::Migration[6.1]
  def change
    add_column :item_update_errors, :itemurl, :string
  end
end
