class AddItemurlToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :itemurl, :string
  end
end
