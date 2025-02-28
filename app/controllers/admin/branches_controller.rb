class Admin::BranchesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_branch, only: [:show, :edit, :update, :destroy]

  def index
    @branches = Branch.all
  end

  def new
    @branch = Branch.new
  end

  def create
    @branch = Branch.new(branch_params)
    if @branch.save
      flash[:notice] = "Cabang berhasil dibuat."
      redirect_to admin_branches_path
    else
      flash.now[:alert] = "Gagal membuat cabang."
      render :new
    end
  end

  def edit
  end

  def update
    if @branch.update(branch_params)
      flash[:notice] = "Cabang berhasil diupdate."
      redirect_to admin_branches_path
    else
      flash.now[:alert] = "Gagal mengupdate cabang."
      render :edit
    end
  end

  def destroy
    @branch.destroy
    flash[:notice] = "Cabang berhasil dihapus."
    redirect_to admin_branches_path
  end

  private

  def set_branch
    @branch = Branch.find(params[:id])
  end

  def branch_params
    params.require(:branch).permit(:name, :location)
  end

  def authorize_admin
    unless current_user.admin?
      flash[:alert] = "Anda tidak memiliki akses untuk area ini."
      redirect_to root_path
    end
  end
end
