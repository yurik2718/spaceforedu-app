Rails.application.routes.draw do
  resource  :session
  resource  :registration, only: %i[new create]
  resources :passwords, param: :token

  resources :conversations, only: :show do
    resources :messages, only: :create
  end

  resources :homologation_requests, only: %i[index new create show edit update] do
    resource  :submission, only: :create, controller: "homologation_request_submissions"
    resources :documents,  only: %i[create destroy], controller: "homologation_request_documents"
  end

  resource  :profile, only: %i[show edit update]
  resources :notifications, only: :index
  resource  :locale, only: :update

  namespace :admin do
    resource :pipeline, only: :show

    resources :homologation_requests, only: :show do
      scope module: :homologation_requests do
        resource  :pipeline_advance,     only: :create
        resource  :pipeline_retreat,     only: :create
        resources :status_transitions,   only: :create
        resources :payment_confirmations, only: :create
        resource  :document_checklist,   only: :update
        resource  :conversation,         only: :create
        resource  :archive,              only: :show
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root to: "pages#home"
end
