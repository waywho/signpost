Rails.application.routes.draw do
  resources :developers do
    member do
      post :prep
    end
    resources :developer_notes, only: [:create]
    resources :oneone_sessions, only: [:index, :show, :new, :create]
  end

  resources :delegations do
    resource :issue, only: [:create], module: :delegations
  end
  resources :commitments, except: [:show, :edit, :update] do
    resource :completion, only: [:create], module: :commitments
  end

  resources :daily_logs, only: [:create, :update]

  resources :pr_reviews, only: %i[index show] do
    member do
      post :analyze
    end
    collection do
      post :ignore
      post :queue_analysis
      get :analyze_pr
      get :run_analysis
    end
  end
  resources :slack_threads, only: %i[index show new create] do
    resource :acknowledgement, only: [:create], module: :slack_threads
    resource :dismissal, only: [:create], module: :slack_threads
    resource :delegation, only: [:create], module: :slack_threads
    resources :slack_topics, only: [] do
      resource :delegation, only: [:create], module: :slack_topics
    end
    resources :codebase_analyses, only: %i[create show] do
      resource :issue, only: [:create], module: :codebase_analyses
      resource :delegation, only: [:create], module: :codebase_analyses
      resource :notification, only: [:create], module: :codebase_analyses
      resource :dismissal, only: [:destroy], module: :codebase_analyses
    end
  end

  get "/search", to: "search#index"
  post "/search", to: "search#create"

  resources :action_items, only: [:update] do
    member do
      post :act
    end
  end

  resource :settings, only: [:show, :update]
  resource :status, only: :show, controller: "status"
  resource :dashboard, only: :show, controller: "dashboard" do
    %i[action_queue insights calendar team_overview active_delegations commitments pr_reviews daily_log].each do |section|
      get section, on: :member
    end
  end

  root "dashboard#show"

  get "up" => "rails/health#show", as: :rails_health_check
end
