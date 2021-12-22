class CsvController < ApplicationController
	def new
	end

	def import
		csv_file = params[:file]
		csv = Csv.create(file_name: csv_file.original_filename,user_id:current_user.id)
		Coupon.import(csv_file,csv.id)

		coupon_cnt = Coupon.where(csv_id: csv.id).count
		csv.update(counts: coupon_cnt)

    redirect_to ("/coupons/index")
	end
end
