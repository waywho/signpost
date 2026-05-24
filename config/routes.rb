Rails.application.routes.draw do
  resources :developers do
    resources :developer_notes, only: [:create]
    resources :oneone_sessions, only: [:index, :show, :new, :create]
  end

  resource :status, only: :show, controller: "status"
  resource :dashboard, only: :show, controller: "dashboard"

  root "dashboard#show"

  get "up" => "rails/health#show", as: :rails_health_check
end
