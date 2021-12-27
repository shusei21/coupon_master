class TokenController < ApplicationController
	def edit
		@token = Token.find_by(user_id: current_user.id)
		if @token.nil?
			@token = Token.new
		end

	end

	def create
		@token = Token.new
		if @token.create(token_params)
			redirect_to home_show_path, notice: "更新しました"
		else
			redirect_to token_edit_path, notice: "更新できませんでした"
		end
	end

	def update
		@token = Token.find_by(user_id: current_user.id)
		@token.update(token_params)

		redirect_to home_show_path, notice: "更新しました"
	end

	private
	def token_params
    params.require(:token).permit(:service_secret, :license_key)
	end

end
