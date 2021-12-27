class AddReserveIdToItemUpdateErrors < ActiveRecord::Migration[6.1]
  def change
    add_column :item_update_errors, :reserve_id, :integer
  end
end
