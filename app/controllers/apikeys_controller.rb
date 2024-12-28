require "bcrypt"

class ApikeysController < ApplicationController
  before_action :authenticate_user!, only: [ :revoke_all, :destroy, :index ]
  skip_before_action :verify_authenticity_token, only: [ :pair ]

  TEMPPIN_VALIDITY=1.hours
  PIN_SIZE = 8

  def destroy
    if params[:id].present?
      begin
        @apikey = Apikey.find(params[:id])
        if @apikey.user == current_user
          @apikey.destroy
          flash[:notice] = "Api key removed."
          redirect_to "/apikeys"
        else
          flash[:notice] = "You do not own that key."
          redirect_to "/apikeys"
          nil
        end
      rescue Mongoid::Errors::DocumentNotFound
        flash[:alert] = "That key does not exist."
        redirect_to "/apikeys"
        nil
      end
    else
      flash[:alert] = "Invalid Request."
      redirect_to "/apikeys"
    end
  end

  def revoke_all
    if current_user.apikeys.destroy
      @error = "Deleted"
      @status = 200
    else
      @error = "No API Key"
      @status = 422
    end

    respond_to do |format|
      format.html {
        flash[:notice] = "All of your API keys have been revoked."
        redirect_to "/apikeys"
      }
      format.json {
        render json: {
                 errors: @error,
                 status: @status
               }, status: @status
      }
    end
  end

  def show
    # This would get called by the client periodically to see if the
    # apikey has been picked up by a user. It doesn't confer any
    # priviledge aside from telling the caller that the temppin was
    # accepted. It is expected that a client poll this endpoint until
    # status=valid and then the client would switch over to using the
    # secret as an identifier for the device.
    #
    # as an additional security measure, this check must happen
    # within the TEMPPIN_VALIDITY time.

    @apikeys = Apikey.all_of({ :temppin => params[:id].downcase,
                              :created_at.gte => Time.now - TEMPPIN_VALIDITY,
                              :valid_for_auth => true
                             })

    if @apikeys.count > 0
      render json: { status: "valid", uid: @apikeys[0].user.id.to_s }, status: 200
    else
      render json: { status: "not valid - forbidden" }, status: 403
    end
  end

  def create
    # this would get called by the device, via .json for the initial token create
    # this call must be over TLS to prevent MiTM of the secret.
    #
    # POST /apikeys/pair
    @apikey = Apikey.new

    if params[:apikey][:name].present?
      @apikey.name = params[:apikey][:name]
    else
      @apikey.name = "TroupeIT Player"
    end

    @apikey.temppin = [ *"a".."z", *"0".."9" ].sample(PIN_SIZE).join

    # after this call, we won't know the secret, but the client will
    # have a chance to stash it away (similar to AWS secrets, you can
    # only see it once.)
    @secret = SecureRandom.hex(32)
    @apikey.secret = BCrypt::Password.create(@secret, cost: 11)
    @apikey.save

    @apikey.secret = @secret
    render json: @apikey
  end

  def index
    @valid_keys = current_user.apikeys.where({ valid_for_auth: true })
    @newapikey = Apikey.new
  end

  def pair
    # POST /apikeys/pair

    # Given a PIN, find a apikey record in the database that is less
    # than TEMPPIN_VALIDITY old and hasn't been used for
    # authentication yet. Link that to the current user's
    # account. Block anyone else from using it in the future for
    # linking.
    #
    # this call must be over TLS to prevent MiTM of the secret.

    if params[:apikey][:temppin].blank?
      flash[:alert] = "You need to enter a PIN."
    else
      # it must be a token that is valid, has the right PIN, and is
      # not currently valid_for_auth (activated)
      @apikeys = Apikey.all_of({ :temppin => params[:apikey][:temppin].downcase,
                                :created_at.gte => Time.now - TEMPPIN_VALIDITY,
                                :valid_for_auth => false
                               })

      if @apikeys.count == 0
        flash[:alert] = "We can't locate that PIN"
      else
        @apikey = @apikeys.first
        @apikey.valid_for_auth = true
        @apikey.user = current_user
        @apikey.save

        flash[:notice] = "Your device is now connected to your account."
      end
    end
    redirect_to url_for(action: :index)
  end
end
