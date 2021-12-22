class Team < ApplicationRecord
	# Userをownerという名前で使う
  # optional: trueで関連先を検査しないようにする
  belongs_to :owner, class_name: 'User', optional: true
  belongs_to :plan, optional: true

  # Team削除時にStripe::Subscriptionも削除
  around_destroy :delete_stripe_subscription_before_destroy

  private

  # Team削除時にStripe::Subscriptionも削除
  def delete_stripe_subscription_before_destroy
    team = self.where(user_id: current_user.id)
    ActiveRecord::Base.transaction do
      # サブスクリプションIDでサブスクリプションを呼び出し
      deleting_stripe_subscription = Stripe::Subscription.retrieve(team.stripe_subscription_id)
      yield
      # データベース上のTeamが削除されたと同時に、stripe側に保存されているサブスクリプションを削除
      deleting_stripe_subscription.delete
    end
  end
end
