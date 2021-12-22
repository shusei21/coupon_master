class AddColumnCsvs < ActiveRecord::Migration[6.1]
  def change
  	add_column :csvs, :user_id, :integer
  end
end
