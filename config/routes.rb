Rails.application.routes.draw do
  # Rute Devise untuk autentikasi user
  devise_for :users

  # Routing untuk cabang dan booking (booking di-nest di dalam cabang)
  resources :branches, only: [:index, :show] do
    resources :bookings, only: [:new, :create]
  end

  # Routing booking untuk aksi reschedule, cancel, dan tampil detail booking
  resources :bookings, only: [:show, :edit, :update, :index] do
    collection do
      get  :new_cs   # Form pembuatan booking customer service
      post :create_cs # Proses pembuatan booking customer service
    end
    member do
      patch :cancel
    end
  end

  # Namespace admin untuk input data cabang, dokter, dan schedule
  namespace :admin do
    resources :branches do 
      member do
        get :timetable
      end
    end
    resources :doctors
    resources :schedules
    resources :bookings
    resources :users, only: [:edit, :update, :destroy] do
      collection do
        get  :customer_services    # List Customer Service
        get  :staffs               # List Staff Cabang
        get  :new_customer_service # Form untuk Customer Service
        post :create_customer_service
        get  :new_staff            # Form untuk Staff Cabang
        post :create_staff
      end
    end
  end

  namespace :staff do
    resources :bookings do
      collection do
        post 'cs_create', action: :create_cs
        get :available_slots
        get :today   # Booking untuk tanggal hari ini
        get :all     # Semua booking dengan filter
        get  :new_cs   # Form pembuatan booking customer service
        get :timetable  
      end
      member do
        patch :cancel    # Untuk membatalkan booking
        patch :complete  # Untuk menandai booking sebagai complete
      end
    end
  end

   root "home#index"
end
