Billing::Application.routes.draw do
  get 'auth' => 'auth#index'
  post 'sign_in' => 'auth#sign_in'
  post 'sign_up' => 'auth#sign_up'

  get 'sign_out' => 'auth#sign_out'

  root :to => 'home#index'
end
