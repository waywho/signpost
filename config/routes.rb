Rails.application.routes.draw do
  resources :developers do
    resource :prep, only: [:create], module: :developers
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

  # PR review collection-level actions (before resources to avoid :id matching)
  scope :pr_reviews, module: :pr_reviews, as: :pr_reviews do
    resource :ignore, only: [:create]
    resource :analysis_job, only: [:create]
    resource :analysis, only: [:show]
  end
  resources :pr_reviews, only: %i[index show create] do
    resource :analysis, only: [:create], module: :pr_reviews
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
    resource :action, only: [:create], module: :action_items
  end

  resource :settings, only: [:show, :update]
  resource :status, only: :show, controller: "status"
  resource :dashboard, only: :show, controller: "dashboard" do
    scope module: :dashboard do
      resource :action_queue, only: :show
      resource :insights, only: :show
      resource :calendar, only: :show
      resource :team_overview, only: :show
      resource :active_delegations, only: :show
      resource :commitments, only: :show
      resource :pr_reviews, only: :show
      resource :daily_log, only: :show
    end
  end

  root "dashboard#show"

  get "up" => "rails/health#show", as: :rails_health_check
end
