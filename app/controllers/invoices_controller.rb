class InvoicesController < ApplicationController
  before_action :authenticate_user!

  def index
    # grab all of this user's invoices
    if current_user.stripe_customer_id.present?
      begin
        Stripe.api_key = ::STRIPE_KEYS[:secret_key]
        Stripe.api_version = "2015-04-07"

        @customer_id = current_user.stripe_customer_id
        @customer = Stripe::Customer.retrieve(@customer_id)

        # uh, what?
        if @customer.nil?
          flash[:alert] = "Could not load your billing history."
          redirect_to "/"
          return
        end

      rescue Stripe::InvalidRequestError
        flash[:alert] = "Failed to retrieve billing history."
        redirect_to "/"
        return
      end
    end

    if @customer.nil?
      flash[:notice] = "You do not have any billing history."
      redirect_to "/"
      nil
    end
  end

  def detail
  end
end
