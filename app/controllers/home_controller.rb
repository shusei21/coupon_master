class HomeController < ApplicationController
  def top
  end

  def show
    @user = User.find_by(id:current_user.id)
  end

  # クレジットカード情報を送ってストライプトークンがcreateアクションに送られてくるのだが
  # https通信ではないやり取りで安全性が確認できないためプロテクトから除外させる
  protect_from_forgery except: :create

  # httpメソッドはpost
  # edit.html.erbのボタンで発動
  def create

    # Customer作成に必要なデータが揃ったか出力して確認
    logger.debug('createアクション実行中')
    logger.debug(params[:stripeToken])# 送られてきたストライプトークンを出力
    logger.debug('current_user.email' + current_user.email)# ログインしているユーザーのメールアドレス
    logger.debug('@current_user.email' + @current_user.email)# ログインしているユーザーのメールアドレス

    # params[:stripeToken]が無くてもCustomerは作れてしまう
    # Customerが作れてしまうからSubscriptionも作れてしまう
    # そのための判定

    # stripetokenが送られてきた場合
    if params[:stripeToken] != nil

      # カスタマーを作る
      customer = Stripe::Customer.create({
        email: current_user.email,# ログインしているユーザーのメールアドレス
        source: params[:stripeToken],# ストライプトークン
      })

      # Customerが作れたかどーかの判定
      if customer.id != nil 
        # customerが作成できたか出力して確認
        logger.debug('customer')
        logger.debug(customer)# customerそのもの
        logger.debug('customer.id')
        logger.debug(customer.id)# customer.id

        # 保存が完了したら、Planを呼び出す(プラン選択はないのでidで良い)
        # Plan名、もしくはidでデータベースからPlanを取り出す
        plan = Plan.find_by(id: 1)# idが1のPlanしか無いので1で良い(フォームでPlanを選ばせるようにするなどの工夫があると良い)

        # Subscriptionの作成に必要なデータが揃ったか出力して確認
        logger.debug('Plan.id')
        logger.debug(plan.stripe_plan_id)# stripe_plan_id

        # 作れていたら、今までに作ってきたデータをTeamに保存
        begin
          Team.transaction() do
            team = Team.new({
              user_id: current_user.id,
              plan_id: plan.stripe_plan_id,# ①プランID
              stripe_card_id: params[:stripeToken],# ②カードトークン
              stripe_customer_id: customer.id,# ③カスタマーID
              active_until: Time.at(Time.now.to_i)})

            # save!でモデルに定義したバリデーションを検証してもらえる
            team.save!

            # trial_endとbilling_cycle_anchorの時間を取得
            trial_end_time = Time.at(Time.local(2018, 12, 31, 12, 0, 0, 0).to_i)# 日時を指定したものをUNIXタイムにしたもの
            billing_cycle_anchor_time = Time.at(Time.local(2018, 12, 31, 12, 28, 0, 0).to_i)# 最初の請求日

            logger.debug('trial_end_time')
            logger.debug(trial_end_time.to_i)# 試用期間終了日
            logger.debug('billing_cycle_anchor_time')
            logger.debug(billing_cycle_anchor_time.to_i)# 最初の請求日

            # アップデートができるか試す
            # team.update( stripe_subscription_id: 'sub_49ty4767H20z6a', active_until: Time.at(Time.now.to_i))

            # エラーが確認できなかったらSubscriptionを作成
            subscription = Stripe::Subscription.create({
              customer: customer.id,
              items: [{plan: plan.stripe_plan_id}],
              tax_percent: 8.00,# 税金(サービスの税金なので税理士に相談して税率を決定)(消費税率にしてるだけ)
              trial_end: trial_end_time.to_i,# 無料の試用期間
              # (試用期間が終わるまでを表したUNIXのタイムスタンプ整数)
              # (早期に終了したい場合はtrial_end: 'now’にする)
              # (trial_period_daysで日数での指定もできるがtrial_endの方が使いやすい)
              # (試用期間終了3日前にWebhookからcustomer.subscription.trial_will_endイベントが送信される)
              # (試用期間終了後invoice.createdイベントが送信される)

              billing_cycle_anchor: billing_cycle_anchor_time.to_i,# 試用期間が終わった初めての請求日の設定
              # (請求日までの時間をUNIXのタイムスタンプ整数にしたもの)
              # (サブスクリプションの通常の定期更新の時の請求日は即時になるが、これがあると請求日サイクル日を設定できる)
              # (この設定がなければ月の最終日に請求がある？)
              # 試用期間終了後は、ここで設定した日付までを日割り計算した金額を即時決済され、設定した日付が来たら請求サイクルで決済される？
              # 例えば2018/8/9に登録したとして、2018/8/9に2018/08/28(月末、月頭でも良い)までの日割り計算された金額を即時決済(licensタイプ)され、請求サイクルの日付は2018/08/28の設定になる
              # キャンセルしたら即座に使えなくなる(Planが'licensed'で前払い性なのでいつ辞めてもそれ以降の金額は関係ない)
              # 前払い性なので、ここで設定した日付から1ヶ月サイクルまで使える状態を作れる


              # billing: 'send_invoice',# 請求書のデフォルト
              # days_until_due: 30,# 未払いを決定する日にち、整数値
              # 数分のPlanの設定やPlanの数量設定もできる
              # items=[
              #   {
              #     "plan": "{{GRADUATED_PLAN_ID}}",
              #     "quantity": "11",# 数量
              #   },
              # ]


            })

            # Subscriptionの実行が完了したら、Subscription_IDをTeamに保存
            # Subscriptionが作れたかどーかの判定
            if subscription.id != nil
              # subscriptionが作成できたか出力して確認
              logger.debug('subscription')
              logger.debug(subscription.id)# customerそのもの
              # ④サブスクリプションID
              # ⑤カスタマーを作った時(サブスクリプションを作った時)の時間
              team.update( stripe_subscription_id: subscription.id, active_until: Time.at(Time.now.to_i))

              # 月額課金がスタートしたので別画面に飛ばす
              render "card/fin_subscription"

            end

          end

          # エラー(バリデーション)が出た場合の処理
        rescue ActiveRecord::RecordInvalid => e
          # e.record.errors
          # 別画面に飛び、エラーメッセージを表示
          render plain: e.message

        end

      end

    end

  end



  # httpメソッドはdelete
  # destroy.html.erbのキャンセルボタンで発動
  def cancel_subscription

    # キャンセルでsubscription_IDが必要になる
    # ログインしているUser(current_user)でTeamを見つけてその中のstripe_subscription_idを取ってくる
    team = Team.find_by(user_id: current_user.id)

    # サブスクリプションが開始されていた場合
    if team.stripe_subscription_id != nil
      # サブスクリプションの停止(キャンセル)
      subscription = Stripe::Subscription.retrieve(team.stripe_subscription_id)
      subscription.delete(at_period_end: true)# 期間終了時にキャンセルのオプション付き

      # 月額課金がキャンセルされたのでレコードから:plan_idと:active_untilとstripe_subscription_idを削除
      # カードトークンとカスタマーIDは残す
      begin
        Team.transaction() do
          team.plan_id = nil
          team.stripe_subscription_id = nil
          team.active_until = Time.at(Time.now.to_i)
          team.save!

          # team.update( plan_id: "", stripe_subscription_id: "", active_until: Time.at(Time.now.to_i))
        end

        # 月額課金をキャンセルしたので別画面に飛ばす
        render "card/fin_subscription"

      # エラー(バリデーション)が出た場合の処理
      rescue ActiveRecord::RecordInvalid => e
        # e.record.errors
        # 別画面に飛び、エラーメッセージを表示
        render plain: e.message

      end

    end

  end



  # httpメソッドはput
  # restart.html.erbの再開ボタンで発動
  def restart_subscription

    # ログインしているUser(current_user)で自分のTeamを見つけてくる
    team = Team.find_by(user_id: current_user.id)

    # Plan名、もしくはidでデータベースからPlanを取り出す
    plan = Plan.find_by(id: 1)# idが1のPlanしか無いので1で良い(フォームでPlanを選ばせるようにするなどの工夫があると良い)
    # Subscriptionの作成に必要なデータが揃ったか出力して確認
    logger.debug('Plan.id')
    logger.debug(plan.stripe_plan_id)# stripe_plan_id

    # trial_endとbilling_cycle_anchorの時間を取得
    trial_end_time = Time.at(Time.local(2018, 12, 31, 12, 0, 0, 0).to_i)# 日時を指定したものをUNIXタイムにしたもの
    billing_cycle_anchor_time = Time.at(Time.local(2018, 12, 31, 12, 28, 0, 0).to_i)# 最初の請求日

    logger.debug('trial_end_time')
    logger.debug(trial_end_time.to_i)# 試用期間終了日
    logger.debug('billing_cycle_anchor_time')
    logger.debug(billing_cycle_anchor_time.to_i)# 最初の請求日

    # アップデートができるか試す
    # team.update( plan_id: 'plan_', stripe_subscription_id: 'sub_', active_until: Time.at(Time.now.to_i))

    # エラーが確認できなかったらSubscriptionを作成
    subscription = Stripe::Subscription.create({
      customer: team.stripe_customer_id,
      items: [{plan: plan.stripe_plan_id}],
      tax_percent: 8.00,# 税金(サービスの税金なので税理士に相談して税率を決定)(消費税率にしてるだけ)
      trial_end: trial_end_time.to_i,# 無料の試用期間
      # (試用期間が終わるまでを表したUNIXのタイムスタンプ整数)
      # (早期に終了したい場合はtrial_end: 'now'にする)
      # (trial_period_daysで日数での指定もできるがtrial_endの方が使いやすい)
      # (試用期間終了3日前にWebhookからcustomer.subscription.trial_will_endイベントが送信される)
      # (試用期間終了後invoice.createdイベントが送信される)
      billing_cycle_anchor: billing_cycle_anchor_time.to_i,# 試用期間が終わった初めての請求日の設定
      # (請求日までの時間をUNIXのタイムスタンプ整数にしたもの)
      # (サブスクリプションの通常の定期更新の時の請求日とは違う。だから定期更新の時の請求日と合わせるとやりやすい)
      # (この設定がなければ月の最終日に請求がある)
      # billing: 'send_invoice',# 請求書のデフォルト
      # days_until_due: 30,# 未払いを決定する日にち、整数値
    })

    # Subscriptionの実行が完了したら、Subscription_IDをTeamに保存
    if subscription.id != nil
      # subscriptionが作成できたか出力して確認
      logger.debug('subscription')
      logger.debug(subscription.id)# customerそのもの
      # ④サブスクリプションID
      # ⑤カスタマーを作った時(サブスクリプションを作った時)の時間

      begin
        Team.transaction() do
          team.plan_id = plan.stripe_plan_id
          team.stripe_subscription_id = subscription.id
          team.active_until = Time.at(Time.now.to_i)
          team.save!

          # team.update( plan_id: plan.stripe_plan_id, stripe_subscription_id: subscription.id, active_until: Time.at(Time.now.to_i))
        end

        # 月額課金がスタートしたので別画面に飛ばす
        render "card/fin_subscription"

      # エラー(バリデーション)が出た場合の処理
      rescue ActiveRecord::RecordInvalid => e
        # e.record.errors
        # 別画面に飛び、エラーメッセージを表示
        render plain: e.message

      end

    end

  end


end
