Spaceship::Application.routes.draw do
  get 'auth' => 'auth#index'
  post 'sign_in' => 'auth#sign_in'
  post 'sign_up' => 'auth#sign_up'

  get 'sign_out' => 'auth#sign_out'

  post 'subscribe' => 'home#subscribe'

  resources :invoices, :only => [:index, :show] do    
    post :pay, :on => :member    
  end
  resources :transactions

  root :to => 'home#index'
end
