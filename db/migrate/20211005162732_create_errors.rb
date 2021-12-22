class CreateErrors < ActiveRecord::Migration[6.1]
  def change
    create_table :errors do |t|
    	t.integer :coupon_id
    	t.string :coupon_name
    	t.string :error_code
    	t.string :error_message

      t.timestamps
    end
  end
end
