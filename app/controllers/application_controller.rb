require "bcrypt"

class ApplicationController < ActionController::Base
  include PublicActivity::StoreController
  include DecidersHelper

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user_from_token!

  protect_from_forgery

  around_action :set_time_zone

  before_action :set_cache_buster
  before_action :configure_permitted_parameters, if: [ :devise_controller? ]
  around_action :profile if Rails.env == "development"

  rescue_from ActionController::RoutingError, with: :render_404
  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  # include mobile_fu but do not change formatting

  # apparently doesn't work anymore? very old.
  # has_mobile_fu false

  def set_time_zone(&block)
    time_zone = current_user.try(:time_zone) || "UTC"
    Time.use_zone(time_zone, &block)
  end

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def profile
#    RubyProf.measure_mode = RubyProf::WALL_TIME
    if params[:profile] && result = RubyProf.profile { yield }
      out = StringIO.new
      RubyProf::GraphHtmlPrinter.new(result).print out, min_percent: 0
      self.response_body = out.string

      f = open("/tmp/last_profile.html", "w")
      f.write(out.string)
      f.close()
    else
      yield
    end
  end

  def render_404
    if /(jpe?g|png|gif)/i === request.path
      render text: "404 Not Found", status: 404
    else
      render template: "shared/404", layout: "application", status: 404
    end
  end

  protected

  def authenticate_user_from_token!
    if request.headers["X-Auth"].present?
      apikey = request.headers["X-Auth"].split(":")

      devices = Apikey.where({ user: apikey[0], valid_for_auth: true })

      auth = false
      user = nil

      if devices.count > 0
        devices.each { |d|
          user_hash = BCrypt::Password.new(d.secret)
          if user_hash == apikey[1]
            logger.info("API Auth from uid #{apikey[0]} Success, device id #{d.id}")
            user = d.user
            auth = true
          end
        }
      else
        logger.info("API Auth from uid #{apikey[0]} - no devices found.")
      end

      if user.present?
        sign_in user, store: false
      else
        logger.info("API Auth from uid #{apikey[0]} - FAILED, no valid keys.")
      end
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username, :name, :phone_number, :email, :password, :password_confirmation, :used_code ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :password, :password_confirmation, :current_password ])
  end
end
