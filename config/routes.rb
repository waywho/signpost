Rails.application.routes.draw do
  resources :developers do
    member do
      post :prep
    end
    resources :developer_notes, only: [:create]
    resources :oneone_sessions, only: [:index, :show, :new, :create]
  end

  resources :delegations do
    member do
      post :create_issue
    end
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
    member do
      post :acknowledge
      post :dismiss
      post :delegate
    end
    resources :slack_topics, only: [] do
      member do
        post :delegate, to: "slack_threads#delegate_topic"
      end
    end
    resources :codebase_analyses, only: %i[create show] do
      member do
        post :create_issue
        post :delegate
        post :notify
        post :dismiss
      end
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
