class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :get_stripe_customer, only: [ :edit_card, :update_card ]

  protect_from_forgery

  def otp_precheck
    if current_user.otp_required == false and current_user.otp_secret_key == nil
      logger.debug("Generate OTP key")

      # generate a secret for the user if this is their first time.
      key = ROTP::Base32.random_base32
      current_user.update_attributes(otp_secret_key: key)
      current_user.save
    end
    render :otp_precheck
  end

  def otp_activate
    if params[:otpcode].present?
      if current_user.authenticate_otp(params[:otpcode]) == true and current_user.valid_password?(params[:password])
        flash[:notice] = "Success. Two-Factor has been enabled for your account."

        current_user.otp_required = true
        current_user.save

        redirect_to "/settings/edit"
        return
      else
        flash[:alert] = "The code or password entered is invalid."
      end
    else
      flash[:alert] = "You must supply a code and your current password to enable Two-Factor."
    end

    render :otp_precheck
  end

  def otp_deactivate
    if current_user.valid_password?(params[:otp_password])
      flash[:notice] = "Two-Factor has been removed from your account. Remember to delete the entry from your authenticator."

      current_user.update_attributes(otp_secret_key: nil)
      current_user.otp_required = false
      current_user.save

    else
      flash[:alert] = "Invalid password."
    end
    redirect_to "/settings/edit"
  end

  def edit
    @user = current_user
  end

  def update
    @user = User.find(current_user.id)

    email_changed = false
    if params[:user][:email].present?
      email_changed = @user.email != params[:user][:email]
    end

    is_oauth_account = !@user.provider.blank?

    if params[:user][:password] == nil
      password_changed = false
    else
      password_changed = !params[:user][:password].empty?
    end

    successfully_updated = if email_changed or password_changed
                             if !is_oauth_account
                               @user.update_with_password(user_params)
                             else
                               @user.update_without_password(user_params)
                             end
    else
                             # this is pretty fucking dumb - we have
                             # to delete these so that devise doesn't
                             # attempt a password change.
                             params[:user].delete(:password)
                             params[:user].delete(:current_password)
                             params[:user].delete(:password_confirmation)

                             @user.update(user_params)
    end

    if successfully_updated

      if email_changed
        # todo - maybe we want to mark these as invalid until we get an update...
        @user.email_valid = true
        @user.save
      end

      # update the sort indices for cm if any.
      @cms = CompanyMembership.where(user: @user)

      @cms.each { |cm|
        cm.sort_name = @user.name.upcase
        cm.sort_username = @user.name.upcase
        cm.save
      }

      # Sign in the user bypassing validation in case their password changed
      sign_in @user, bypass: true

      respond_to do |format|
        format.html {
          flash[:notice] = "Your profile has been updated."

          if params[:confirm].present?
            redirect_to "/settings/confirm_mobile"
          else
            if params[:remove].present?
              current_user.sms_capable = false
              current_user.sms_confirmed = false
              current_user.phone_number = ""
              current_user.sms_notifications = false
              current_user.save

              flash[:notice] = "Your mobile number has been removed"
            end
            redirect_to "/settings/edit"
          end

          return
        }
        format.json { render json: { errors: "OK" }  }
      end
    else
      respond_to do |format|
        format.html { render "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def confirm_mobile
    # roll a random number
    current_user.sms_confirmed = false
    current_user.sms_capable = false
    current_user.sms_confirmation_code = (SecureRandom.random_number(899999) + 100000).to_s

    # store it
    current_user.save

    # send it via twillo
    begin
      TwilioMsg.message_user(current_user, "TroupeIT: Your verification code is #{current_user.sms_confirmation_code}", true)
    rescue Twilio::REST::RequestError
      flash[:alert] = "Either your phone number is invalid or it is not in a supported country."
      redirect_to "/settings/edit"
    end
    # show the confirmation screen
  end


  def verify_mobile
    if params[:user][:code] == current_user.sms_confirmation_code
      current_user.sms_capable = true
      current_user.sms_confirmed = true
      current_user.sms_notifications = true
      current_user.sms_sleep_enabled = false
      current_user.save
      flash[:info] = "Your mobile phone has been confirmed."

      # send it via twillo
      TwilioMsg.message_user(current_user, "TroupeIT: Your mobile phone has been confirmed. Thank you!", false)
      redirect_to "/settings/edit"
    else
      flash[:alert] = "That confirmation code is invalid. Please try again."
      render :confirm_mobile
    end
  end

  def edit_card
    # just show our form
  end

  def update_card
    if not params[:stripe_card_token].present?
      flash[:alert] = "Invalid request."
      redirect_to "/settings/edit"
      return
    end

    @stripe_customer.card = params[:stripe_card_token]
    @stripe_customer.save

    # for every company they own, flush the failed bit so we can retry
    current_user.companies.each { |c|
      c.payment_failed = false
      c.save
    }

    flash[:notice] = "Your card has been updated."
    redirect_to "/settings/edit_card"
  end

  def extend_trial
    # hitting this link will reset your trial if and only if we've emailed you that your trial is over.
    r = Resetkey.where({ token: params["t"] })
    if r.count > 0
      r.first.destroy
      current_user.reset_trial_expiration
      current_user.trial_extended = true
      current_user.save

      StatsD.increment("troupeit.users.trial_resets")

      flash[:notice] = "Thanks for coming back. Your 30 day trial period starts now."
      redirect_to "/"
      return
    end

    StatsD.increment("troupeit.users.failed_resets")
    flash[:alert] = "We're sorry, your reset link has already been used or is invalid."
    redirect_to "/"
  end

  private

  def get_stripe_customer
    if current_user.stripe_customer_id.present?
      Stripe.api_key = ::STRIPE_KEYS[:secret_key]
      @stripe_customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
      @stripe_pk = STRIPE_KEYS[:publishable_key]
    else
      flash[:alert] = "You do not have a credit card on file at this time."
      redirect_to "/settings/edit"
    end
  end

  def user_params
    params.require(:user).permit(:name, :username, :email, :password, :password_confirmation, :remember_me, :used_invite, :disable_tutorial, :cover_uuid, :avatar_uuid, :phone_number, :time_zone, :sms_sleep_enabled, :sms_sleep_end_hh, :sms_sleep_end_mm, :sms_sleep_start_hh, :sms_sleep_start_mm, :location, :miniresume, :share_email, :share_phone, :live_view_columnpref)
  end
end
