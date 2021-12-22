class CreateCommons < ActiveRecord::Migration[6.1]
  def change
    create_table :commons do |t|
    	t.string :user_id
    	t.string :common_bnr_name
    	t.string :common_bnr_url

      t.timestamps
    end
  end
end
