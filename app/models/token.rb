class Token < ApplicationRecord
	attr_encrypted :service_secret, key: Rails.application.credentials.token[:service_secret_token]
  attr_encrypted :license_key, key: Rails.application.credentials.token[:license_key_token]

  validates :user_id, uniqueness: true
end
