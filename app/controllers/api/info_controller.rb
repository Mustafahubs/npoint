class Api::InfoController < ApplicationController
  protect_from_forgery with: :null_session # Disable CSRF

  # Renders at https://api.npoint.io
  #
  # People often go to this page by mistake, looking for wwww. Point them in
  # the right direction. Could put API version info here.
  def index
    render json: {
      homepage: "https://#{ENV.fetch('HOST', 'localhost')}",
      contact: "sgocean25@gmail.com"
    }
  end
end
