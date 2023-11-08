# 概要
CSVを使って楽天市場で使えるクーポンを一括発行できるプログラムです。【店舗運営者向】

# プログラム作成の背景
楽天のイベント（お買い物マラソン等）に合わせ、クーポン発行による割引を実施するが、
クーポンの発行は1枚ずつしかできない上、設定する項目が多く、時間がかかる。<br>
1枚のクーポンに複数商品を含めることも可能だが、下記理由により商品毎に作成することを求められていた。<br>

* 商品毎に最適な割引額にしたい。<br>
* 商品毎にクーポン使用率（使用数/獲得数）の分析をしたい。<br>

一度に30枚以上のクーポンを発行する事となり、かなりの工数が掛かっていた。<br><br>

そこで、楽天の提供しているクーポンAPIとCSVを利用して、複数のクーポンを一括作成するプログラムを作成した。<br>
またその際、クーポン割引額のデータを利用して、商品ページにバナーを設置する作業も半自動化した。<br>

# 作業フロー
![flow](/flow.jpg)

# ER図
![ER](/ER.jpg)

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
