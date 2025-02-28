class HomeController < ApplicationController
    def index
      if user_signed_in?
        case current_user.role
        when "admin"
          # Misalnya, admin diarahkan ke dashboard admin (ganti sesuai kebutuhan)
          redirect_to admin_branches_path
        when "customer_service"
          # Customer Service bisa diarahkan ke halaman booking (atau menu khusus CS)
          redirect_to bookings_path
        when "staff_cabang"
          # Staff Cabang diarahkan ke daftar booking cabang mereka
          redirect_to all_staff_bookings_path
        else
          redirect_to root_path  # fallback jika role tidak dikenali
        end
      else
        # Jika belum login, arahkan ke halaman login atau landing page
        redirect_to new_user_session_path
      end
    end
  end
  