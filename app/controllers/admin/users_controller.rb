class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_user, only: [:edit, :update, :destroy]

  # List Customer Service
  def customer_services
    @users = User.where(role: "customer_service")
  end

  # List Staff Cabang
  def staffs
    @users = User.where(role: "staff_cabang")
  end

  # Form untuk membuat Customer Service
  def new_customer_service
    @user = User.new(role: "customer_service")
  end

  def create_customer_service
    @user = User.new(customer_service_params)
    @user.role = "customer_service"
    if @user.save
      flash[:notice] = "Customer Service berhasil dibuat."
      redirect_to customer_services_admin_users_path
    else
      flash.now[:alert] = "Gagal membuat Customer Service."
      render :new_customer_service
    end
  end

  # Form untuk membuat Staff Cabang
  def new_staff
    @user = User.new(role: "staff_cabang")
  end

  def create_staff
    @user = User.new(staff_params)
    @user.role = "staff_cabang"
    if @user.save
      flash[:notice] = "Staff Cabang berhasil dibuat."
      redirect_to staffs_admin_users_path
    else
      flash.now[:alert] = "Gagal membuat Staff Cabang."
      render :new_staff
    end
  end

  # Action Edit dan Update untuk kedua tipe user (tetap sama)
  def edit
  end

  def update
    permitted_params = if @user.customer_service?
                         params.require(:user).permit(:email, :name, :password, :password_confirmation)
                       elsif @user.staff_cabang?
                         params.require(:user).permit(:email, :name, :branch_id, :password, :password_confirmation)
                       else
                         params.require(:user).permit(:email, :name, :password, :password_confirmation)
                       end

    if @user.update(permitted_params)
      flash[:notice] = "User berhasil diupdate."
      if @user.customer_service?
        redirect_to customer_services_admin_users_path
      elsif @user.staff_cabang?
        redirect_to staffs_admin_users_path
      else
        redirect_to customer_services_admin_users_path
      end
    else
      flash.now[:alert] = "Gagal mengupdate user."
      render :edit
    end
  end

  def destroy
    @user.destroy
    flash[:notice] = "User berhasil dihapus."
    redirect_back(fallback_location: root_path)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def customer_service_params
    params.require(:user).permit(:email, :name, :password, :password_confirmation)
  end

  def staff_params
    params.require(:user).permit(:email, :name, :branch_id, :password, :password_confirmation)
  end

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Akses hanya untuk admin."
      redirect_to root_path
    end
  end
end
