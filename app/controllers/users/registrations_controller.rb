class Users::RegistrationsController < Devise::RegistrationsController
  def new
    # if we're requiring invite codes, we're not going to let them see the
    # new page unless the invite code is valid. after that, if they manage
    # to make more accounts, oh well...

    # we will also allow signups if the user is attempting to accept an invite

    if DECIDER("signups_public") == 0.0 and not !!/\/invitation\/[0-9a-f]+\/accept/.match(session["user_return_to"])
      if params[:invite_code].present?
        @invites = SignupInvite.where({ code: /#{params[:invite_code]}/i })

        if @invites.count == 0
          # this code isn't valid. back to the home page with you.
          logger.debug ("invalid invite code")
          redirect_to("/?ni=1")
          return
        end

      else
        logger.debug ("no invite code and code required")
        # no invite, no access.
        redirect_to("/?ni=1")
        return
      end
    end

    # run devise's code...
    super
  end

  # DELETE /resource
  def destroy
    Stripe.api_key = ::STRIPE_KEYS[:secret_key]
    Stripe.api_version = "2015-04-07"

    if current_user.stripe_customer_id.present?
      begin
        customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)

        customer.subscriptions.each { |s|
          s.delete(at_period_end: true)
          StatsD.increment("troupeit.billing.subscription.cancelled_ok")
        }

      rescue Stripe::InvalidRequestError
        # Probably because the customer id is long gone. log and move on...
        logger.info("Error: Stripe Invalid request while trying to delete customer " + current_user.stripe_customer_id)
      end
    end

    resource.soft_delete

    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed if is_flashing_format?
    yield resource if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  def after_sign_up_path_for(resource)
    StatsD.increment("troupeit.user.signups")
    "/?signupcomplete=1" # Or :prefix_to_your_route
  end
end
