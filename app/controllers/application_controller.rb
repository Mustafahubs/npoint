class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # See http://alexzirbel.com/npoint-csrf-test/ for a live test.
  protect_from_forgery with: :exception, prepend: true unless Rails.env.development?

  # Skip CSRF for JSON API requests (check Content-Type since clients may not send Accept header)
  skip_before_action :verify_authenticity_token, if: :json_request?

  rescue_from Exception, with: :internal_server_error
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :missing_param
  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :bad_request_body

  protected

  def json_request?
    request.content_type =~ /application\/json/
  end

  def not_found
    head :not_found
  end

  def internal_server_error
    head :internal_server_error
  end

  def missing_param
    head :bad_request
  end

  def invalid_authenticity_token
    head :unprocessable_entity
  end

  def bad_request_body
    head :bad_request
  end
end
