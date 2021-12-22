class AddCountsToCsvs < ActiveRecord::Migration[6.1]
  def change
  	add_column :csvs, :counts, :integer
  end
end
