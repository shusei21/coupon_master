class CreatePlans < ActiveRecord::Migration[6.1]
  def change
    create_table :plans do |t|
    	t.string :stripe_plan_id,       null: false# nameと同じ名前でOK
      t.string :name,                 null: false# プランの名前
      t.integer :amount,              null: false# 値段
      t.string :currency,             null: false# 通貨名
      t.string :interval,             null: false# 課金周期(月額month)

      t.timestamps
    end
  end
end
