Rails.application.routes.draw do
  devise_for :users
  root 'home#top'
  get 'home/show'
  post 'home/create'
  get 'card/edit'# app/views/card/edit.html.erb画面にアクセス
  get 'card/destroy'# app/views/card/destroy.html.erb画面にアクセス
  get 'card/restart'# app/views/card/restart.html.erb画面にアクセス
  get 'card/fin_subscription'# app/views/card/fin_subscription.html.erb画面にアクセス
  get 'csv/new'
  post 'csv/import'
  get 'coupons/top' => 'coupons#top'
  get 'coupons/index'
  post 'coupons/create' => 'coupons#create'
  get 'token/:id' => 'token#edit'
  post 'token/create' => 'token#create'
  patch 'token/update' => 'token#update'
  get 'items/get' => 'items#get'
  post 'items/add_update' => 'items#add_update'
  post 'items/remove_update' => 'items#remove_update'
  get 'reserves/index' => 'reserves#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
