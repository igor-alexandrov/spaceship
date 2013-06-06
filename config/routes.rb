Billing::Application.routes.draw do
  get 'auth' => 'auth#index'
  post 'sign_in' => 'auth#sign_in'
  post 'sign_up' => 'auth#sign_up'

  root :to => 'home#index'
end
