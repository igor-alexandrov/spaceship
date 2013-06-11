Spaceship::Application.routes.draw do
  get 'auth' => 'auth#index'
  post 'sign_in' => 'auth#sign_in'
  post 'sign_up' => 'auth#sign_up'

  get 'sign_out' => 'auth#sign_out'  

  resources :invoices, :only => [:index, :show] do
    post :pay, :on => :member
  end

  resources :transactions

  resources :cards, :only => [:new, :create, :destroy]

  post '/' => 'home#subscribe', :as => 'subscribe'
  post '/finish_trial' => 'home#finish_trial'
  root :to => 'home#index'
end
