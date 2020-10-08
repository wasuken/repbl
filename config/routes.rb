Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'repos', to: "repos#index"
      post 'repos', to: "repos#create"
      delete 'repo/:id', to: 'repos#destroy'
    end
  end
  get '/', to: 'repos#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
