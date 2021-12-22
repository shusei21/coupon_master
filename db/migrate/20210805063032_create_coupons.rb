class CreateCoupons < ActiveRecord::Migration[6.1]
  def change
    create_table :coupons do |t|
    	t.string :csv_id
    	t.string :name
    	t.string :caption
    	t.datetime :startdate
    	t.datetime :enddate
    	t.string :image
    	t.integer :issuecount
    	t.integer :itemtype
    	t.integer :discounttype
    	t.integer :discountfactor
    	t.integer :maxcount
    	t.integer :rankcond
    	t.integer :combineflag
    	t.integer :displayflag
    	t.string :itemurl
    	t.string :conditiontype
    	t.string :startvalue
    	t.integer :common_bnr
    	t.integer :coupon_bnr

      t.timestamps
    end
  end
end
