class TokenController < ApplicationController
	def edit
		@token = Token.find_by(user_id: current_user.id)
		if @token.nil?
			@token = Token.new
		end

	end

	def create
	end

	def update
		@token = Token.find_by(user_id: current_user.id)
		@token.update(token_params)

		redirect_to('/token/edit')
	end

	private
	def token_params
    params.require(:token).permit(:service_secret, :license_key)
	end

end
