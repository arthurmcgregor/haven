class UploadsController < ApplicationController
  include MediaProcessing

  before_action :authenticate_user!

  def create
    if params[:file].blank?
      return render json: { error: "No file provided" }, status: :unprocessable_entity
    end

    _image, html, url, type = attach_media(params[:file])
    render json: { url: url, html: html, type: type }
  rescue ActiveRecord::RecordInvalid, ActiveStorage::IntegrityError => e
    Rails.logger.error "Upload rejected: #{e.message}"
    render json: { error: "Could not save upload" }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "Upload failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if e.backtrace
    render json: { error: "Upload failed" }, status: :internal_server_error
  end
end
