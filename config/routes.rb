Rails.application.routes.draw do
  resource :status, only: :show, controller: "status"
  resource :dashboard, only: :show, controller: "dashboard"

  root "dashboard#show"

  get "up" => "rails/health#show", as: :rails_health_check
end
