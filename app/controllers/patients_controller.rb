class PatientsController < ApplicationController
  layout 'internal_form'

  def new
    @patient = Patient.new
    @booking = Booking.find_by(id: params[:booking]) if params[:booking].present?
  end

  def create
    @patient = Patient.new(patient_params)
    if @patient.save
      redirect_to today_staff_bookings_path  , notice: 'Data pasien berhasil disimpan.'
    else
      render :new
    end
  end

  private

  def authenticate_staff_cabang!
    # Ganti sesuai logic autentikasi staff cabang di aplikasi Anda
    unless current_user&.staff_cabang?
      redirect_to root_path, alert: 'Anda tidak memiliki akses.'
    end
  end

  def patient_params
    params.require(:patient).permit(
      :full_name, :identity_number, :gender, :place_of_birth, :date_of_birth, :phone_number, :email, :address,
      :village, :district, :city, :province, :blood_type, :emergency_contact_name, :emergency_contact_phone
    )
  end
end
