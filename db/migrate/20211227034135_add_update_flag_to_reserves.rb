class AddUpdateFlagToReserves < ActiveRecord::Migration[6.1]
  def change
    add_column :reserves, :update_flag, :integer
  end
end
