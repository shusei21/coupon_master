class AddIndex < ActiveRecord::Migration[6.1]
  def change
  	add_index :tokens, :user_id, unique: true
  end
end
