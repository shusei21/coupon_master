class CreateItems < ActiveRecord::Migration[6.1]
  def change
    create_table :items do |t|
    	t.string :coupon_id
    	t.datetime :startdate
    	t.datetime :enddate
    	t.string :image_name
    	t.string :coupon_url

      t.timestamps
    end
  end
end
