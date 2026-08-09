class RegistrationsController < Devise::RegistrationsController
  clear_respond_to
  respond_to :json

  private

  def sign_up_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def account_update_params
    params.permit(:name, :email, :password, :password_confirmation, :current_password)
  end

  # Override devise default so we always respond with JSON.
  #
  # Uses resource.errors (already populated by Devise's own save/update/
  # destroy call) rather than re-validating resource here. Re-validating
  # used to be done by writing params[:password] back onto resource and
  # calling resource.valid? - but Devise's clean_up_passwords wipes
  # password_confirmation back to nil on a failed save, and
  # validates_confirmation_of skips validation entirely when the
  # confirmation value is nil, so a real password/confirmation mismatch
  # would silently re-validate as "valid" and look like a successful signup
  # even though the record was never persisted. The same write also raised
  # FrozenError on the (already destroyed) resource in the destroy action.
  def respond_with(resource, *ignored)
    if action_name == 'destroy'
      head resource.destroyed? ? :ok : :unprocessable_entity
      return
    end

    if resource.errors.empty?
      render json: resource, serializer: UserSerializer, status: request.post? ? :created : :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
