class CreateTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :tokens do |t|
      t.string :service_secret
    	t.string :encrypted_service_secret
    	t.string :encrypted_service_secret_iv
      t.string :license_key
    	t.string :encrypted_license_key
    	t.string :encrypted_license_key_iv
    	t.integer :user_id

      t.timestamps
    end
  end
end
