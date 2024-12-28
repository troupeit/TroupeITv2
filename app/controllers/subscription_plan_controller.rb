class SubscriptionPlanController < ApplicationController
  protect_from_forgery except: :webhook

  before_action :authenticate_user!, except: :webhook
  before_action :configure_stripe

  def webhook
    # do we need these?
    #
    # invoice.payment_succeeded - If an invoice is paid update the
    # paid until dates
    #
    # invoice.payment_failed - If an invoice is unpaid, consider
    # locking the account
    #
    # from the stripe UI... (do we need these?)
    # customer.deleted
    # customer.updated
    #

    if params[:type].blank?
      @result_code = 400
      @status_text = "Missing type"
    else
      case params[:type]
      when "customer.subscription.deleted"
        StatsD.increment("troupeit.billing.webhook.subscription.deleted")
        disable_subscription(params[:data][:object][:id])
      when "customer.subscription.created"
        StatsD.increment("troupeit.billing.webhook.subscription.created")
        set_subscription_end(params[:data][:object][:id],
                             params[:data][:object][:current_period_end])
      when "customer.subscription.updated"
        StatsD.increment("troupeit.billing.webhook.subscription.updated")
        if params[:data][:object][:status] != "past_due"
          set_subscription_end(params[:data][:object][:id],
                               params[:data][:object][:current_period_end])
        end
      when "invoice.payment_failed"
        StatsD.increment("troupeit.billing.webhook.invoice.payment_failed")

        c = Company.where({ stripe_subscription_id: params[:data][:object][:lines][:data][0][:id] }).first
        if not c.nil?
          @result_code = 200
          @status_text = "Ok. Marked as failed"
          c.payment_failed = true
          c.save
        else
          @result_code = 400
          @status_text = "Could not find subscription"
        end

      else
        StatsD.increment("troupeit.billing.webhook.ignored")
        @result_code = 200
        @status_text = "Ok, but webhook ignored."
      end
    end

    # right now we're just gonna return 200 OK,
    respond_to do |format|
      format.xml  { render text: @status_text, status: @result_code }
      format.html { render text: @status_text, status: @result_code }
      format.json { render json: { errors: @status_text, status: @result_code }, status: @result_code }
    end
  end

  def charge
    # Get the credit card details submitted by the form
    token = params[:stripetoken]

    # verify company and plan
    begin
      @company = Company.find(params[:company_id])
    rescue Mongoid::Errors::DocumentNotFound
      flash[:error] = "We could not complete your payment because the request was invalid."
      respond_to do |format|
        format.json { render json: { errors: "invalid company", transstatus: "invalid", status: 422 }, status: 422 }
      end
      return
    end

    @plan = SubscriptionPlan.where({ stripe_id: params[:plan] }).first

    if @plan.nil?
      flash[:error] = "We could not complete your payment because the request was invalid."
      respond_to do |format|
        format.json { render json: { errors: "invalid plan", transstatus: "invalid", status: 422 }, status: 422 }
      end
      return
    end

    begin

      # Find or create a customer, then create a new subscription as needed.
      if current_user.stripe_customer_id.blank?
        customer = Stripe::Customer.create(
          source: token,
          email: current_user.email,
          description: current_user.name
        )
        current_user.stripe_customer_id = customer.id.to_s
        current_user.save
      else
        customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
      end
      StatsD.increment("troupeit.billing.subscription.create")
      subscription = customer.subscriptions.create({ plan: @plan.stripe_id,
                                                    metadata: { company_name: @company.name,
                                                                   company_id: @company._id.to_s
                                                                 }
                                                   })
      @company.stripe_subscription_id = subscription.id
      @company.last_payment = Time.now.utc
      @company.stripe_customer_id = customer.id.to_s

      # Update this so the refresh is correct. We'll get the accurate
      # paid-through time from stripe, as a webhook, in just a moment.
      if @plan.interval == "year"
        @company.paid_through = Time.now + @plan.interval_count.year
      else
        @company.paid_through = Time.now + @plan.interval_count.month
      end

      @company.subscription_plan = @plan
      @company.save

      flash[:notice] = "Thank you for your purchase! We've updated your company."

      # TODO: nicer thank-you page
      respond_to do |format|
        format.json { render json: { errors: "OK", transstatus: "Charged", status: 200 }, status: 200 }
      end

      return
    rescue Stripe::CardError => e
      flash[:notice] = "We're sorry, Your card was declined, please try again."
      StatsD.increment("troupeit.billing.declined")
      respond_to do |format|
        format.json { render json: { errors: "Declined", transstatus: "declined", status: 200 }, status: 200 }
      end
      return
    end

    redirect_to "/companies/" + @company.id.to_s + "/billing"
  end


  def change
    # verify company and plan
    begin
      @company = Company.find(params[:company_id])
    rescue Mongoid::Errors::DocumentNotFound
      flash[:alert] = "We could not complete your payment because the request was invalid."
      respond_to do |format|
        format.html {     redirect_to "/companies/" + @company.id.to_s + "/billing" }
        format.json { render json: { errors: "invalid company", transstatus: "invalid", status: 422 }, status: 422 }
      end
      return
    end

    @plan = SubscriptionPlan.where({ stripe_id: params[:plan] }).first

    if @plan.nil?
      flash[:alert] = "We could not complete your payment because the request was invalid."
      respond_to do |format|
        format.html {     redirect_to "/companies/" + @company.id.to_s + "/billing" }
        format.json { render json: { errors: "invalid plan", transstatus: "invalid", status: 422 }, status: 422 }
      end
      return
    end
    if @company.subscription_plan.present? and @company.stripe_customer_id.present?
      begin
        customer = Stripe::Customer.retrieve(@company.stripe_customer_id)
        subscription = customer.subscriptions.first
        subscription.plan = @plan.stripe_id
        subscription.save

        # if they change periods, the billing date becomes today.
        if @company.subscription_plan.interval != @plan.interval
          if @plan.interval == "year"
            @company.paid_through = Time.now + 1.year
          else
            @company.paid_through = Time.now + 1.month
          end
        end
        @company.subscription_plan = @plan
        @company.save
        flash[:notice] = "We have changed your billing plan."
        StatsD.increment("troupeit.billing.plan_changed")
      rescue
        flash[:error] = "We are unable to process your change request."
      end
    else
      flash[:error] = "You do not have an existing plan to change."
    end

    redirect_to "/companies/" + @company.id.to_s + "/billing"
  end


  def cancel
    begin
      @company = Company.find(params[:company_id])
    rescue Mongoid::Errors::DocumentNotFound
      flash[:error] = "We could not complete your cancellation request because the company does not exist."
      respond_to do |format|
        format.html { redirect_to "/companies" }
        format.json { render json: { errors: "invalid company", transstatus: "invalid", status: 422 }, status: 422 }
      end
      return
    end

    # sanity check
    if current_user.stripe_customer_id.blank? or @company.stripe_subscription_id.blank?
      flash[:error] = "You have no purchase history or the company does not have a subscription."
      respond_to do |format|
        format.html { redirect_to "/companies" }
        format.json { render json: { errors: "invalid cancellation", transstatus: "invalid", status: 422 }, status: 422 }
      end
      return
    end

    begin

      customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
      subscription = customer.subscriptions.retrieve(@company.stripe_subscription_id)
      if subscription.nil?
        flash[:alert] = "We could not find your subscription. Please contact customer support if you are still being charged."
        StatsD.increment("troupeit.billing.cancel.notfound")
        # clear it out, because obviously it's no good.
        @company.subscription_plan = nil
        @company.save
        return
      end
      subscription.delete(at_period_end: true)
      flash[:notice] = "Your subscription has been cancelled. You may continue to use any remaining time in your plan."
      StatsD.increment("troupeit.billing.subscription.cancelled_ok")
      # we will wait for stripe to send us an event to actually cancel the account...
    rescue Stripe::InvalidRequestError
      flash[:alert] = "We could not find your subscription. Please contact customer support if you are still being charged."
      StatsD.increment("troupeit.billing.subscription.cancel_failure")
      @company.subscription_plan = nil
      @company.save
    end

    redirect_to "/companies/" + @company.id.to_s + "/billing"
  end

  private

  def configure_stripe
    Stripe.api_key = ::STRIPE_KEYS[:secret_key]
    Stripe.api_version = "2015-04-07"
    @stripe_pk = STRIPE_KEYS[:publishable_key]
  end

  def set_subscription_end(subscription, end_t)
    c = Company.where({ stripe_subscription_id: subscription }).first

    if c.nil?
      @status_text = "Subscription not found."
      # unfortunately we have to accept here or stripe will mark our webhook
      # as broken. This is usually a cancellation and we can move on.
      @result_code = 200
      nil
    else
      # insert the time_t as our paid-through
      c.paid_through = end_t
      c.payment_failed = false
      c.save
      logger.debug("WEBHOOK (#{params[:id]}): Set customer #{c._id} paid_through #{c.paid_through} - OK")
      @status_text = "Subscription Updated"
      @result_code = 200
    end
  end

  def disable_subscription(subscription)
    c = Company.where({ stripe_subscription_id: subscription }).first

    if c.nil?
      @status_text = "Subscription not found."
      # unfortunately we have to accept here or stripe will mark our webhook
      # as broken. This is usually a cancellation and we can move on.
      @result_code = 200
      nil
    else
      # insert the time_t as our paid-through
      c.paid_through = nil
      c.subscription_plan_id = nil

      if c.save
        logger.debug("WEBHOOK (#{params[:id]}): Disable Company Subscription #{c._id} - OK")
        @status_text = "Subscription Destroyed"
        @result_code = 200
      else
        logger.info("WEBHOOK (#{params[:id]}): Failed to disable Company Subscription #{c_id} - FAIL")
        @status_text = "Subscription delete failure"
        @result_code = 500
      end

    end
  end
end
