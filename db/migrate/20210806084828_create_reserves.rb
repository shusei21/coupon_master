class CreateReserves < ActiveRecord::Migration[6.1]
  def change
    create_table :reserves do |t|
    	t.string :item_id
    	t.text :html

      t.timestamps
    end
  end
end
