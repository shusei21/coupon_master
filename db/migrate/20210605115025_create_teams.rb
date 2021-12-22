class CreateTeams < ActiveRecord::Migration[6.1]
  def change
    create_table :teams do |t|
      t.string  :plan_id# プランID
      t.integer :user_id# 月額課金をキャンセル、再開時に必要なのでcurrent_user.idを保存する
      t.string   :stripe_card_id# カードトークン
      t.string   :stripe_customer_id# カスタマーID
      t.string   :stripe_subscription_id# サブスクリプションID
      t.datetime :active_until, null: false# カスタマーを作った時の時間

      t.timestamps
    end
  end
end
