# true/false monkeypatch - I had to add this again for this class, no idea why.
require "#{Rails.root}/lib/yesno.rb"

class CompaniesController < ApplicationController
  protect_from_forgery

  before_action :authenticate_user!

  before_action :configure_stripe

  before_action :set_company, except: [ :adminindex, :index, :new, :create ]
  before_action :get_company_stats, only: [ :billing, :edit, :invite_codes ]

  before_action :must_be_admin, only: [ :adminindex, :makecomp ]

  before_action :must_be_producer,
                only: [ :edit, :update, :destroy, :billing, :manage_access, :regenerate, :invite_codes ]

  # GET /companies/nnnnn/members.json
  def members
    if @company.present?
      @cm = CompanyMembership.where(company_id: @company).order_by({ access_level: :desc, sort_name: :asc })
    else
      @cm = []
    end

    # Privacy-filter the resultant json to only show data if the users have allowed it.
    @filtered = []

    is_member = @company.has_member?(current_user)
    @cm.each { |cm|
      # reset this on each loop
      allowed_user_data = [ :_id, :provider, :uid, :name, :username, :avatar_uuid, :cover_uuid ]

      # if you are a member of this company
      if is_member
        # and that user has chosen to share their data, you can see their info.
        if cm.user.share_email
          allowed_user_data << :email
        end

        if cm.user.share_phone
          allowed_user_data << :phone_number
        end
      end

      @filtered << { membership: cm, user: cm.user.as_json(only: allowed_user_data) }
    }

    render json: { company: @company, members: @filtered }
  end

  def adminindex
    @ajaxurl = "/companies/adminindex.json"
    @companies = Company.all
    @companydt = []

    @companies.each { |t|
      u=nil
      if t.user_id
        begin
           u = User.only(:name, :_id).find(t.user_id)
        rescue Mongoid::Errors::DocumentNotFound
           u = nil
        end
      end

      @companydt << { company: t, owner: u }
    }

    respond_to do |format|
      format.html { render "index" }
      format.json { render json:  @companydt.to_json }
    end
  end

  # GET /companies
  # GET /companies.json
  def index
    @ajaxurl = "/companies.json"
    case params[:type]
    when "all"
      @companies = Company.all
    when "public"
      @companies = Company.where(private: false).not_in(user_id: current_user.id)
    else
      # companies you own and are a member of.
      @cm = CompanyMembership.where(user_id: current_user.id)
      @companies = Company.in(_id: @cm.map(&:company_id))
      @companiesjson = Company.in(_id: @cm.map(&:company_id)).as_json(include: :subscription_plan)
    end

    @companydt = []

    @companies.each { |t|
      u=nil
      if t.user_id
        begin
          u = User.only(:name, :_id).find(t.user_id)
        rescue Mongoid::Errors::DocumentNotFound
          u = nil
        end
      end

      @companydt << { company: t, owner: u }
    }

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json:  @companydt.to_json }
    end
  end

  # GET /companies/1
  # GET /companies/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @company }
    end
  end

  # GET /companies/new
  # GET /companies/new.json

  def new
    # you have to have one company in good standing to make more
    # than one company.
    # for all companies that the user owns...
    @owned = Company.where({ user: current_user })

    # count how many are paid up to date...
    @paid_companies = 0

    @owned.each { |oc|
      if oc.paid_through
        if oc.paid_through >= Time.now
          @paid_companies = @paid_companies + 1
        end
      end
    }

    # if they don't own any companies, or, if owned == paid, they can continue.
    if @owned.count != @paid_companies and @owned.count != 0 and not current_user.try(:admin?)
      flash[:alert] = "To create additional companies, you must have valid subscriptions for your existing companies."
      redirect_to "/"
      return
    end

    @company = Company.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @company }
    end
  end

  # GET /companies/1/edit
  def edit
  end

  # POST /companies
  # POST /companies.json
  def create
    @company = Company.new(company_params)
    @company.user_id = current_user.id
    StatsD.increment("troupeit.companies.create")

    @existing = Company.where(name: /^#{company_params[:name]}$/i)

    if @existing.count > 0
      respond_to do |format|
        # 200 OK = request ok but not created

        format.html {
          flash[:alert] = "That company name is already in use."
          render action: "new"
        }

        format.json { render json: @company.errors, status: :ok }
      end
      return
    end

    respond_to do |format|
      if @company.save
        # create the default invite codes -- user can disable later
        make_default_invites @company

        # add the user to the company via CompanyMembership
        tm = CompanyMembership.new
        tm.user_id = current_user.id
        tm.company_id = @company.id

        # first user is the owner and has full access
        tm.access_level = 8
        tm.save

        format.html { redirect_to "/companies", notice: "Company was successfully created." }
        # 201 Created = all good
        format.json { render json: @company, status: :created, location: @company }
      else
        format.html { render action: "new" }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /companies/1
  # PUT /companies/1.json
  def update
    @company = Company.find(params[:id])
    StatsD.increment("troupeit.companies.update")

    respond_to do |format|
      if @company.update(company_params)
        format.html { redirect_to "/companies/", notice: "Company was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    if @company.user_id != current_user.id
      respond_to do |format|
        format.html { redirect_to companies_url, notice: "You do not own that company." }
        format.json { render json:  { errors: "Forbidden. You are not the owner of this company." }, status: 403 }
      end
      return
    end

    @invitations = Invitation.where({ company_id: @company._id.to_s })
    @invitations.destroy

    if @company.paid_through.present?
      if current_user.stripe_customer_id.present? and @company.stripe_subscription_id.present? and @company.paid_through >= Time.now()
        begin
          customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
          subscription = customer.subscriptions.retrieve(@company.stripe_subscription_id)
          subscription.delete(at_period_end: true)
          StatsD.increment("troupeit.billing.subscription.cancelled_ok")
        # we will wait for stripe to send us an event to actually cancel the account...
        rescue Stripe::InvalidRequestError
          # well, do nothing I guess, the subscription wasn't valid.
          # this shouldn't happen given our if statement above, but it might...
          logger.info("Stripe::InvalidRequestError while trying to delete subscription #{@company.stripe_subscription_id}")
          StatsD.increment("troupeit.billing.subscription.cancel_failure")
        end
      end
    end

    @company.destroy

    StatsD.increment("troupeit.companies.destroy")

    flash[:notice] = "Company deleted."

    # debug: forcibly return 200 ok
    respond_to do |format|
      format.html { redirect_to companies_url }
      format.json { render json: { status: "Deleted." }, status: 200 }
    end
  end


  def leave
    current_user.company_memberships.each { |tm|
      if tm.company_id == @company.id
        tm.destroy
        redirect_to "/companies/", notice: "You have left company \"#{tm.company.name}\""
        return
      end
    }

    redirect_to "/companies/", notice: "You are not a member of that company."
  end

  def join
    # are we already a member?
    current_user.company_memberships.each { |tm|
      if tm.company_id and tm.company_id == @company.id
         respond_to do |format|
           format.html { redirect_to "/companies/", notice: "You are already a member of \"#{@company.name}\"." }
           format.json { head :no_content }
         end
         return
      end
    }

    # TODO: private check or auth-code check goes here

    if @company.private == true and params[:auth].empty?
         respond_to do |format|
           format.html { redirect_to "/companies/", notice: "You cannot join that company. It is private." }
           format.json { head :no_content }
         end
         return
    end

    StatsD.increment("troupeit.companies.join")

    # add the user to the company
    tm = CompanyMembership.new
    tm.user_id = current_user.id
    tm.company_id = @company.id
    tm.save

    respond_to do |format|
      format.html { redirect_to "/companies/", notice: "Joined company: #{@company.name}" }
      format.json { head :no_content }
    end
  end


  # invite_codes.json
  def invite_codes
    @invitations = Invitation.where({ company_id: @company._id.to_s, type: 128 })
    respond_to do |format|
      format.html # invite_codes
      format.json {
        render json: { invite_codes: @invitations,
                       company: @company,
                       crew_count: @crew_count,
                       performer_count: @performer_count,
                       plan: @current_plan
                     }
      }
    end
  end

  # POST regenerate.json
  def regenerate
    # if producer, regenerate the invites for the company
    @invitations = Invitation.where({ company_id: @company._id.to_s, type: 128 })
    @invitations.destroy

    make_default_invites @company

    @invitations = Invitation.where({ company_id: @company._id.to_s, type: 128 })
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @invitations }
    end
  end

  def billing
    if DECIDER("momoney") != 1
      redirect_to "/companies", alert: "Invalid URL"
      return
    end

    @cancelled_plan = false
    # load the subscription plan, if they have one.
    if current_user.stripe_customer_id.present?
      @stripe_customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
      if @company.stripe_subscription_id.present?
        begin
          @stripe_subscription = @stripe_customer.subscriptions.retrieve(@company.stripe_subscription_id)
        rescue Stripe::InvalidRequestError
          # this can happen if the subscription doesn't exist
          logger.info("Stripe::InvalidRequestError while trying to load subscription #{@company.stripe_subscription_id} for company #{@company.id}")
          @cancelled_plan == true
        end

        # stripe misspells "canceled". great!
        if @stripe_subscription.present?
          if @stripe_subscription.canceled_at.present?
            @cancelled_plan = true
          end
        end
      end
    end

    @plans = SubscriptionPlan.where({ active: 1 }).where({ :stripe_id.ne => "COMP" })
  end

  def make_comp
    @company.make_comp!
    flash[:notice] = "Company set to complimentary access"
    redirect_to "/users/#{@company.user.id}"
  end

  private

  # Only allow a trusted parameter "white list" through.
  def company_params
    params.require(:company).permit(:name, :description, :long_description, :private, :invite_required, :members_can_invite)
  end

  def make_default_invites(company)
    CMACCESS.keys.each { |ac|
      i = Invitation.new
      i.type=INVITE_COMPANY
      i.company_id = company._id.to_s
      i.single_use = false
      i.access_level = ac
      i.save
    }
  end

  def must_be_admin
    if current_user.try(:admin?) == false
      respond_to do |format|
        format.html { redirect_to "/companies", alert: "Insufficent Access." }
        format.json { render json:  { errors: "Forbidden" }, status: 403 }
      end
    end
  end

  def set_company
    begin
      @company = Company.find(params[:id])
    rescue
      respond_to do |format|
        format.html { redirect_to "/", alert: "Company does not exist." }
        format.json { render json: { error: "Not Found" }, status: 404 }
      end
    end
  end

  def must_be_producer
    @cms = CompanyMembership.where({ user: current_user, company: @company })

    if @cms.count == 0
      respond_to do |format|
        format.html { redirect_to "/", alert: "You are not a member of that company." }
        format.json { render json: { error: "permission denied" }, status: 403 }
      end
    else
      if @cms[0].access_level != CM_PRODUCER
        respond_to do |format|
          format.html { redirect_to "/", alert: "You have insufficent access to edit that company." }
          format.json { render json: { error: "permission denied" } }
        end
      end
    end
  end

  def get_company_stats
    # produce an company status report for billing. We'll use these
    # queries elsewhere in the system to compute limits. Note that
    # this is dependent on @company, so call :set_company first.

    @crew_count = CompanyMembership.where({ company: @company }).gte(access_level: 2).count
    @performer_count = CompanyMembership.where({ company: @company, access_level: 0 }).count
    @events_month = Event.where({ company: @company }).gte(created_at: Date.today.at_beginning_of_month).count

    if @company.subscription_plan.nil?
      @current_plan = SubscriptionPlan.find_by(stripe_id: "FREE")
    else
      @current_plan = @company.subscription_plan
    end
  end

  def configure_stripe
    Stripe.api_key = ::STRIPE_KEYS[:secret_key]
    Stripe.api_version = "2015-04-07"
    @stripe_pk = STRIPE_KEYS[:publishable_key]
  end
end
