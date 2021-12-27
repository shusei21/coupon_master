class CreateItemUpdateErrors < ActiveRecord::Migration[6.1]
  def change
    create_table :item_update_errors do |t|
      t.integer :error_id
      t.integer :firld_id
      t.string :error_msg

      t.timestamps
    end
  end
end
