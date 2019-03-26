# frozen_string_literal: true

class Api::V1::ApiController < ApplicationController
  protect_from_forgery with: :null_session
  rescue_from Exception, with: :show_errors
  before_action :set_default_format

  private

  def set_default_format
    request.format = :json
  end

  def show_errors(exception)
    error_json = return_error(exception.to_s)
    render json: error_json, status: error_json[:status]
  end
end
