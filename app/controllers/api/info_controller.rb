class Api::InfoController < ApplicationController
  protect_from_forgery with: :null_session # Disable CSRF

  # Renders at the root of the API subdomain (e.g.
  # https://api-npoint.fastapi.us on this fork's live demo, or api.<HOST>
  # locally - see API_SUBDOMAIN in config/routes.rb).
  #
  # People often go to this page by mistake, looking for wwww. Point them in
  # the right direction. Could put API version info here.
  def index
    render json: {
      homepage: "#{ENV.fetch('PUBLIC_PROTOCOL', 'http')}://#{ENV.fetch('HOST', 'localhost')}",
      contact: "sgocean25@gmail.com"
    }
  end
end
