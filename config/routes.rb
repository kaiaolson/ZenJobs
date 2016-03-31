Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  root "welcome#home"

  # custom actions for the welcome controller
  get "/home" => "welcome#home"
  get "/demo" => "welcome#demo"
  get "/features" => "welcome#features"
  get "/pricing" => "welcome#pricing"


  resources :sessions, only: [:new, :create] do
    delete :destroy, on: :collection
  end
  resources :password_resets, only: [:new, :create, :edit, :update]
  resources :users do
    get "/change_password" => "users#change_password"
  end
  resources :clients, only: [:new, :create, :index, :destroy]

  resources :categories
  resources :info_requests do
    resources :submissions, only: [:new, :create, :show, :edit, :update, :destroy]
  end
  resources :submissions, only: [:index, :show]
  resources :relationships, only: [:create, :destroy]

  resources :teams
  resources :team_memberships

  resources :client_requests, only: [:index]
  resources :client_submissions, only: [:index]
  resources :consultant_requests, only: [:index]
  resources :consultant_submissions, only: [:index]

  resources :conversations, only: [:index, :show, :new, :create] do
    member do
      post :reply
      post :trash
      post :untrash
    end
  end

  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      resources :users, only: [:index] do
        post "sign_in" => "users#sign_in", on: :collection
        delete "sign_out" => "users#sign_out", on: :collection
      end
    end
  end
end
