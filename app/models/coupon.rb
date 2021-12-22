class Coupon < ApplicationRecord
	has_many :items
  has_many   :reserve, through: :items 
	belongs_to :csv

	def self.import(file,id)
    CSV.foreach(file.path, headers: true) do |row|
      coupon = new
      # CSVからデータを取得し、設定する
      coupon.attributes = row.to_hash.slice(*csv_attributes)
      coupon.csv_id = id
      # 保存する
      coupon.save!
    end
  end

  # 更新を許可するカラムを定義
  def self.csv_attributes
    ["name","caption","startdate","enddate","image","issuecount","itemtype","discounttype","discountfactor","maxcount","rankcond","combineflag","displayflag","itemurl","conditiontype","startvalue","common_bnr","coupon_bnr","common_url"]
  end
end
