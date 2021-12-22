class Csv < ApplicationRecord
	has_many :coupons
	belongs_to :user

	def self.import(file)
    CSV.foreach(file.path, headers: true) do |row|
      # IDが見つかれば、レコードを呼び出し、見つかれなければ、新しく作成
      coupon = new
      # CSVからデータを取得し、設定する
      coupon.attributes = row.to_hash.slice(*csv_attributes)
      # 保存する
      coupon.save!
    end
  end

  # 更新を許可するカラムを定義
  def self.csv_attributes
    ["name","caption","startdate","enddate","image","issuecount","itemtype","discounttype","discountfactor","maxcount","rankcond","combineflag","displayflag","itemurl","conditiontype","startvalue","common_bnr","coupon_bnr","common_url"]
  end
end
