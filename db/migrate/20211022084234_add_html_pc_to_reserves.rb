class AddHtmlPcToReserves < ActiveRecord::Migration[6.1]
  def change
    add_column :reserves, :html_pc, :text
    add_column :reserves, :html_sp, :text
  end
end
