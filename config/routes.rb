Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'repos', to: 'repos#index'
      get 'repos/:id', to: 'repos#show'
      post 'repos', to: 'repos#create'
      delete 'repos/:id', to: 'repos#destroy'

      get 'rfiles/:repoId/:rfileId', to: 'rfiles#show'
    end
  end
  get '/', to: 'repos#index'
  get '/repos', to: 'repos#index'
  get '/repos/:id', to: 'repos#show'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
