PayalogueExample::Application.routes.draw do
  root :to => "home#index"
  resources :products, :only => [:index, :show]
  match "/report" => "purchases#report"
end
