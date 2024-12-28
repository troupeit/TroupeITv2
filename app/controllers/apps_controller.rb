class AppsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cache_buster
  before_action :check_scoring_closed

  #  before_action :check_bhof_member, only: [:index, :dashboard]

  before_action :set_app, only: [ :show, :dashboard, :edit, :update, :destroy, :lock, :unlock, :review, :resultmodal, :rsvp ]
  before_action :check_app_owner, only: [ :show, :dashboard, :edit, :update, :destroy, :unlock, :rsvp ]
  before_action :check_bhof_judge, only: [ :review, :adminindex, :finalreport ]
  before_action :check_bhof_judge_or_scorer, only: [ :scoreindex ]
  before_action :get_current_round, only: [ :review, :adminindex, :scoreindex ]

  before_action :check_deadline_passed
  before_action :abort_if_deadline, only: [ :create, :new, :lock, :express_checkout, :update, :edit ]

  before_action :check_edit_allowed, only: [ :edit, :update ]

  before_action :find_next_id, only: [ :review, :edit, :update ]

  before_action :remember_state, only: [ :review, :adminindex ]

  protect_from_forgery

  def finalreport
    logger.debug("in finalreport")

     @apps = App.where({ locked: true, event_code: ::BHOF_EVENTCODE }).group_by(&:final_decision)

     # fetch the scores.
     @appscores = Rails.cache.fetch("appscores-final-" + (current_user.has_role?(:bhof_judge) ? "1" : "0"), expires_in: 60.minutes) do
       @appscores = Hash.new
       [ 0, 6, 9, 7, 10, 8, 1, 2, 3, 4, 5 ].each { |a|
         if @apps[a].present?
           @apps[a].each { |ae|
             reviews = Bhofreview.where(app_id: ae.id)
             stats = calc_stats(ae, reviews)
             @appscores[ae.id] = { scores: reviews, stats: calc_stats(a, reviews) }
           }
         end
       }
       @appscores
     end

     # build the csv hash
     @csvarry = Array.new
     [ 6, 9, 7, 10, 8, 1, 2, 3, 4, 5 ].each { |a|
       if @apps[a].present?
         @categorysorted = @apps[a].sort_by { |obj| obj.entry.name }
         @categorysorted.each { |ae|
           @csvout = Hash.new

           @csvout["name"] = ae.entry.name
           @csvout["email"] = ae.user.email
           @csvout["from"] = ae.entry.city_from
           @csvout["submitter_name"] = ae.user.name
           @csvout["act_description"] = ae.description
           @csvout["type"] = view_context.type_to_s(ae.entry.type)
           @csvout["category"] = view_context.cat_to_s(ae.entry.category)
           @csvout["compete_preference"] = view_context.compete_to_s(ae.entry.compete_preference)
           @csvout["performers"] = ae.entry.num_performers ? ae.entry.num_performers : 1
           @csvout["performer_url"] = ae.entry.performer_url
           @csvout["video_url"] = ae.entry.video_url
           @csvout["rsvp"] = ae.decision_rsvp

           @csvarry << @csvout
         }
       end
     }

     respond_to do |format|
       format.html { render "finalreport" }
       format.csv  {
         row=0
         out = CSV.generate do |csv|
           @csvarry.each do |h|
             if row == 0
               csv << h.keys
             end
             csv << h.values
             row=row+1
           end
         end

         render plain: out
       }
     end
  end

  def finalvideos
    # special request - show videos of final accepted acts. No scores or reviews here.
    @apps = App.where({ locked: 1, event_code: ::BHOF_EVENTCODE }).group_by(&:final_decision)
    # build the csv hash
    @csvarry = Array.new
    [ 6, 9, 7, 10, 8, 1, 2, 3, 4, 5 ].each { |a|
      if @apps[a].present?
        @categorysorted = @apps[a].sort_by { |obj| obj.entry.name }
        @categorysorted.each { |ae|
          @csvout = Hash.new

          @csvout["name"] = ae.entry.name
          @csvout["email"] = ae.user.email
          @csvout["from"] = ae.entry.city_from
          @csvout["submitter_name"] = ae.user.name
          @csvout["act_description"] = ae.description
          @csvout["type"] = view_context.type_to_s(ae.entry.type)
          @csvout["category"] = view_context.cat_to_s(ae.entry.category)
          @csvout["performers"] = ae.entry.num_performers ? ae.entry.num_performers : 1
          @csvout["performer_url"] = ae.entry.performer_url
          @csvout["video_url"] = ae.entry.video_url
          @csvout["rsvp"] = ae.decision_rsvp

          @csvarry << @csvout
        }
      end
    }

    respond_to do |format|
      format.html { render "finalvideos" }
      format.csv  {
        row=0
        out = CSV.generate do |csv|
          @csvarry.each do |h|
            if row == 0
              csv << h.keys
            end
            csv << h.values
            row=row+1
          end
        end

        render plain: out
     }
    end
  end

  def resultmodal
    @rsvp_deadline = ::BHOF_RSVP_DEADLINE

    # hidden variable for testing
    if params[:testfr].present?
      @app.final_decision=params[:testfr].to_i
    end

    render ::BHOF_FINAL_FILEMAP[@app.final_decision], layout: false
  end

  # POST /apps/appid/unlock
  def unlock
    # applications can be locked via POST request if the user owns the application
    # but they can only be unlocked by a judge/admin
    if current_user.try(:admin?) or current_user.has_role?(:bhof_judge)
      if @app
         @app.locked = false
         @app.save
         flash[:notice] = "Application Unlocked."
      end
    else
        flash[:alert] = "You must be an administrator to do that."
    end

    # obviously, they're an admin, send them back there.
    redirect_to dashboard_app_path(@app)
  end

  # POST /apps/id/lock
  def lock
    if @app
      @app.locked=true
      @app.save
      redirect_to dashboard_app_path(@app)
    else
      flash[:alert] = "Can't lock that application"
      redirect_to "/apps/"
    end
  end

  def rsvp
    if @app and params[:state].present?
      @app.decision_rsvp = params[:state].to_i
      @app.save

      if params[:state].to_i == 1
        flash[:notice] = "RSVP has been saved. Thanks for accepting!"
      else
        flash[:notice] = "RSVP has been saved. We're sorry you declined."
      end
      redirect_to apps_path
    else
      flash[:alert] = "Can't RSVP for that application"
      redirect_to "/apps/"
    end
  end

  def scoreindex
     # large-format mass-update page for judges and scoring
     @roundfilter = 0

     if params[:roundfilter].to_i > 0
       @roundfilter = params[:roundfilter]
     end

     @catfilter = 0

     if params[:catfilter].present?
       @catfilter = params[:catfilter].to_i
     end

     @apps = Rails.cache.fetch("scoreapps-#{@catfilter}-" + (current_user.has_role?(:bhof_judge) ? "1" : "0"), expires_in: 60.minutes) do
       logger.debug("CACHE: no cache for scoreapps")
       if @catfilter != 0
         if @catfilter == 4
           @incat = Entry.where(:type.gte => 2)
         else
           @incat = Entry.where(category: @catfilter)
         end

         if current_user.has_role?(:bhof_judge)
           @apps = App.in(id: @incat.map(&:app_id)).where({ locked: 1, event_code: ::BHOF_EVENTCODE })
         else
           @apps = App.in(id: @incat.map(&:app_id)).where({ locked: 1, event_code: ::BHOF_EVENTCODE, forward_for_review: 1 })
         end
       else
         if current_user.has_role?(:bhof_judge)
           @apps = App.where({ locked: true, event_code: ::BHOF_EVENTCODE })
         else
           @apps = App.where({ locked: true, event_code: ::BHOF_EVENTCODE, forward_for_review: 1 })
         end
       end
       @apps
     end

     # fetch the scores.
     @appscores = Rails.cache.fetch("appscores-#{@catfilter}-" + (current_user.has_role?(:bhof_judge) ? "1" : "0"), expires_in: 60.minutes) do
       @appscores = Hash.new
       logger.debug("CACHE: no cahe for appscores")

       @apps.each { |a|
         reviews = Bhofreview.where(app_id: a.id)
         stats = calc_stats(a, reviews)
         @appscores[a.id] = { scores: reviews, stats: calc_stats(a, reviews) }
       }
       @appscores
     end

     # recalculate all of the reviews for this user -- we should cache this, this sucks (0.075 Secs I think)
     # hard to cache because it can change at any time.
     @userscores = Hash.new
     @apps.each { |a|
         @userscores[a.id.to_s] = Bhofreview.where({ app_id: a.id, judge_id: current_user.id })[0]
     }

     respond_to do |format|
       format.html { render "scoreindex" }
       format.json { render json: { "aaData" => @apps } }
     end
  end

  def adminindex
    if current_user.try(:admin?) or current_user.has_role?(:bhof_judge)

      @stat_apps = Rails.cache.fetch(:stat_apps, expires_in: 1.minutes) do
        ast = Hash.new
        ast["cnt"] = App.where(event_code: ::BHOF_EVENTCODE).count
        ast["submitted"] = App.where({ locked: 1, event_code: ::BHOF_EVENTCODE }).count
        ast["paid"] = App.where({ :purchased_at.gt => 0, event_code: ::BHOF_EVENTCODE }).count
        ast["paid_nosubmit"] = App.where({ locked: nil, event_code: ::BHOF_EVENTCODE }).exists({ purchased_at: true }).count
        ast["rated_one"] = 0
        ast["rated_three"] = 0
        ast["rated_more"] = 0

        apps = App.where({ locked: 1, event_code: ::BHOF_EVENTCODE })
        apps.each { |a|
           if a.bhofreviews.present?
             if a.bhofreviews.count > 3
               ast["rated_more"] = ast["rated_more"] + 1
             end

             if a.bhofreviews.count >= 3
               ast["rated_three"] = ast["rated_three"] + 1
             end

             if a.bhofreviews.count >= 1
               ast["rated_one"] = ast["rated_one"] + 1
             end

           end
        }

        ast
      end

      @catfilter = 0

      if params[:catfilter].present?
        @catfilter = params[:catfilter].to_i
      end

      # this is a very expensive operation. On the order of 3-5
      # seconds, cache it. Invalidate this cache if there is a change
      # in scores.
      @avgsorted = Rails.cache.fetch("avgsorted-#{@catfilter}-#{params[:incomplete]}", expires_in: 30.minutes) do
      if params[:incomplete] == "1"
        if @catfilter != 0
          if @catfilter == 4
            @incat = Entry.where(:type.gte => 2)
          else
            @incat = Entry.where(category: @catfilter)
          end
          @apps = App.where(event_code: ::BHOF_EVENTCODE).in(id: @incat.map(&:app_id))
        else
          @apps = App.where(event_code: ::BHOF_EVENTCODE)
        end
      else
        if @catfilter != 0
          if @catfilter == 4
            @incat = Entry.where(:type.gte => 2)
          else
            @incat = Entry.where(category: @catfilter)
          end
          @apps = App.in(id: @incat.map(&:app_id)).where({ locked: 1, event_code: ::BHOF_EVENTCODE })
        else
          @apps = App.where({ locked: 1, event_code: ::BHOF_EVENTCODE })
        end
      end

      @appsarray = []
      @apps.each { |a|
        description = ""
        status = "Not Started"
        # TODO: move all of this code to the modal, DRY it up, something like "status.to_s"
        performername = ""
        category = ""
        type = ""

        if a.entry.present?
          if a.entry.category.present?
            if a.entry.category == 1
              category = "Female"
            elsif a.entry.category == 2
              category = "Female/Debut"
            elsif a.entry.category == 3
              category = "Male/Boylesque"
            else
              category = "Unknown"
            end
          end
        end

        if a.entry
          type = a.entry.type.present? ? BHOF_TYPES[a.entry.type] : ""
          performername = a.entry.name.present? ? a.entry.name : ""

          if a.entry.nil? or
                a.entry_techinfo.nil? or
                a.is_complete? == false or
                a.entry.is_complete? == false or
                a.entry_techinfo.is_complete? == false or
                a.purchased_at.nil?
            if a.purchased_at.present?
              status = "Paid"
            else
              status = "Incomplete"
            end
          else
            if a.locked
              status = "Submitted"
            else
              status = "Needs Submission"
            end
          end
        end

        avg = 0
        reviews = Bhofreview.where({ app_id: a.id })
        rstat = calc_stats(a, reviews)

        if a.entry.present? and a.entry.compete_preference.present?
          comppref = BHOF_COMP_PREF[a.entry.compete_preference]
        else
          comppref = "Unknown"
        end

        @appsarray << { "created" => a.created_at.to_time.in_time_zone("US/Pacific").strftime(SHORT_TIME_FMT_TZ),
                       "user" => a.user.username,
                       "type" => type,
                       "category" => category,
                       "performername" => performername,
                       "description" => a.description,
                       "status" => status,
                       "comppref" => comppref,
                       "min_score_s" => rstat["min_s"],
                       "min_score" => rstat["min"],
                       "max_score_s" => rstat["max_s"],
                       "max_score" => rstat["max"],
                       "avg_score_s" => rstat["avg_s"],
                       "avg_score" => rstat["avg"],
                       "norm_score_s" => rstat["norm_s"],
                       "norm_score" => rstat["norm"],
                       "review_cnt" => reviews.count,
                       "final_decision" => a.final_decision,
                       "id" => a.id.to_s }
      }

      @avgsorted = @appsarray.sort { |y, x| x["avg_score"] <=> y["avg_score"] }
      cnt = 1
      @avgsorted.each { |a|
          a["rank"] = cnt
          cnt += 1
      }
      @avgsorted
    end
      respond_to do |format|
        format.html { render action: "adminindex" }
        format.csv {
          # Look, I know we're doing this twice, but it might be
          # cached, it might not.  we need fresh data for export
          # here.
          if params[:incomplete] == "1" then
            @with_lockstatus = [ nil, false ]
          else
            @with_lockstatus = [ true ]
          end

          @apps = App.where({ :locked.in => @with_lockstatus, event_code: ::BHOF_EVENTCODE })
          render text: @apps.to_csv
        }
        format.json { render json: { "aaData" => @avgsorted } }
      end
    else
      flash[:alert] = "You must be an administrator to do that."
      redirect_to "/apps/"
    end
  end

  # GET /review
  def review
    # this is the review process where an applicaiton is displayed
    myreview = Bhofreview.where({ judge_id: current_user.id, app_id: @app.id })

    # seed the input form for this person's review.
    if myreview.length != 0
      @bhofreview = myreview[0]
    else
      @bhofreview = Bhofreview.new
    end

    @entry = @app.entry
    @entry_techinfo = @app.entry_techinfo


    # collect and calcuate the reviews for everyone else
    reviews = Bhofreview.where(app_id: @app.id)
    @rstat = calc_stats(@app, reviews)
  end

  # GET /apps
  def index
    @apps = current_user.apps.where({ event_code: ::BHOF_EVENTCODE })
    @apps_incomplete = 0
    @apps_accepted = 0

    if DECIDER("bhof2024_decisions") > 0
      @deadlinedate = BHOF_RSVP_DEADLINE
    else
      @deadlinedate = BHOF_FINAL_DEADLINE
    end

    if @apps
      @apps.each { |a|
         # an application is incomplete if both tests fail.
         # we could check for locked here, as you can only lock when
         # complete, but we're trying to be complete.
         if a.complete? == false or a.locked.present? == false
           @apps_incomplete = @apps_incomplete + 1
         end

         if a.final_decision > 0
           @apps_accepted = @apps_accepted + 1
         end
      }
    end
  end

# GET /apps/1
def show
    # we actually use dashboard instead of show...
    redirect_to dashboard_app_path(@app)
  end

  # get /apps/updateme
  def updateme
    @app = Apps.where(user_id: current_user.__id__)
  end

  # GET /apps/new
  def new
    if DECIDER("app_create_enabled") != 1
      redirect_to apps_path, alert: "This event is not currently open for applications."
      return
    end

    if current_user.bhof_member_id.blank?
      redirect_to "/bhof/page1", alert: "You need to verify your BHOF membership to create applications."
      return
    end

    @app = App.new
  end

  # GET /apps/1/edit
  def edit
  end

  # POST /apps
  def create
    if DECIDER("app_create_enabled") != 1
      redirect_to apps_path, alert: "This event is not currently open for applications."
      return
    end

    @app = App.new(app_params)
    @app.created_at=Time.now
    @app.event_code = ::BHOF_EVENTCODE

    if @app.save
      StatsD.increment("troupeit.apps.create")
      current_user.apps << @app
      current_user.save!

      redirect_to dashboard_app_path(@app), notice: "Application was successfully created."
    else
      render action: "new"
    end
  end

  # PATCH/PUT /apps/1
  def update
    @catfilter = 0

    if params[:catfilter].present?
      @catfilter = params[:catfilter].to_i
    end

    if (params[:app][:forward_for_review].present? or params[:app][:final_decision].present?) and not current_user.has_role?(:bhof_judge)
      respond_to do |format|
        format.html { redirect_to apps_url, alert: "You must be a judge to update that field" }
        format.json { head :forbidden }
      end
      return
    end

    if @app.update(app_params)
      StatsD.increment("troupeit.apps.update")

      # well, this'll be expensive.
      Rails.cache.delete("avgsorted-0-0")
      Rails.cache.delete("avgsorted-1-0")
      Rails.cache.delete("avgsorted-2-0")
      Rails.cache.delete("avgsorted-3-0")
      Rails.cache.delete("avgsorted-4-0")
      Rails.cache.delete("avgsorted-0-1")
      Rails.cache.delete("avgsorted-1-1")
      Rails.cache.delete("avgsorted-2-1")
      Rails.cache.delete("avgsorted-3-1")
      Rails.cache.delete("avgsorted-4-1")

      respond_to do |format|
        format.html { redirect_to apps_url, notice: "Application was successfully updated." }
        format.json { render json: @app }
      end

    else
      render action: "edit"
    end
  end

  # DELETE /apps/1
  def destroy
    @app.destroy

    if request.env["HTTP_REFERER"].include?("/adminindex")
      StatsD.increment("troupeit.apps.destroy")
      redirect_to adminindex_apps_path, notice: "Application was successfully destroyed."
    else
      redirect_to apps_url, notice: "Application was successfully destroyed."
    end
  end

  def dashboard
    @stripe_pk = STRIPE_KEYS[:publishable_key]
    @entry = @app.entry
    @entry_tech = @app.entry_techinfo
  end

  def payment_cancel
    begin
      @app = App.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      @error = "Application went away during processing. Please try again."
      redirect_to apps_url, notice: @error
      return
    end

    # TODO: Clear the token here? Not sure if it matters at all.
    redirect_to dashboard_app_path(@app), notice: "Payment has been cancelled."
  end


  def payment_paid
    # paypal sends a get request to here, when done,
    #  but we're not done yet, we have to capture funds.
    #
    # sample callback...
    # http://hubba-dev.retina.net/apps/54615c637265747d8a000000/payment_paid?token=EC-47X445308L645073U&PayerID=F9BZ2FNUEB95N
    begin
      @app = App.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      @error = "Application went away during processing. Please try again."
      redirect_to apps_url, notice: @error
      return
    end

    # have to stash this away for purchase use later. An order is only complete if
    # purchased_at not nil
    @app.purchase_ip = request.remote_ip
    @app.express_token = params[:token]
    @app.express_payer_id = params[:PayerID]
    @app.save

    if @app.purchase
      @app.purchased_at = Time.now
      if @app.save
        redirect_to dashboard_app_path(@app), notice: "Thank you for your payment!"
      else
        redirect_to dashboard_app_path(@app), alert: "Payment failed to process. Please try again."
        logger.notice("Application #{@app.id} failed to save after payment processed.")
      end
    else
      redirect_to dashboard_app_path(@app), alert: "Your payment failed."
    end
  end

  def express_checkout
    begin
      @app = App.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to "/apps", alert: "You must specify an application for payment"
    rescue Mongoid::Errors::InvalidFind
      redirect_to "/apps", alert: "You must specify an application for payment"
    end

    # purchase price is in cents, per paypal's API, USD ($1.00 = 100 cents)
    @app.purchase_price = @app.get_current_price()
    @app.save

    response = EXPRESS_GATEWAY.setup_purchase(@app.purchase_price,
      ip: request.remote_ip,
      return_url: "#{BHOF_URL}/apps/#{@app.id}/payment_paid",
      cancel_return_url: "#{BHOF_URL}/apps/#{@app.id}/payment_cancel",
      currency: "USD",
      allow_guest_checkout: true,
      items: [ { name: "BHOF #{BHOF_YEAR}", description: "BHOF #{BHOF_YEAR} Application", quantity: "1", amount: @app.get_current_price() } ]
  )

  redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token)
  end

  def remember_state
    @catfilter = params[:catfilter]
    @dir = params[:dir]
    @sort = params[:sort]
  end

  def users
    # if you're an admin, you can get user data.
    if not current_user.try(:admin?)
        flash[:alert] = "You must be an administrator to do that."
        redirect_to "/"
        return
    end

    @apps = App.where({ :locked.in => [ 0, 1 ], event_code: ::BHOF_EVENTCODE }).distinct(:user)
    ignored_attributes = [ "encrypted_password", "role_ids", "last_sign_in_ip", "current_sign_in_ip" ]

    csv_string =  User.find(@apps[0]).attributes.delete_if { |attr, value| ignored_attributes.include?(attr) }.keys.to_csv

    csv_string << CSV.generate do |csv|
      @apps.each do |a|
         csv << User.find(a).attributes.delete_if { |attr, value| ignored_attributes.include?(attr) }.values
      end
    end

    begin
      respond_to do |format|
        format.csv { render text: csv_string }
      end
    rescue ActionController::UnknownFormat
      raise ActionController::RoutingError.new("Not Found")
    end
  end

  def charge
    # Get the credit card details submitted by the form
    token = params[:stripetoken]

    # verify the app
    begin
      @app = App.find(params[:app_id])
    rescue Mongoid::Errors::DocumentNotFound
      flash[:error] = "We could not complete your payment because the request was invalid."
      respond_to do |format|
        format.json { render json: { errors: "invalid app", transstatus: "invalid", status: 422 }, status: 422 }
      end
      return
    end

    begin
      Stripe.api_key = ::STRIPE_KEYS[:secret_key]
      Stripe.api_version = "2015-04-07"

      # Find or create a customer, then create a new subscription as needed.
      if current_user.stripe_customer_id.blank?
        # new customer
        customer = Stripe::Customer.create(
          source: token,
          email: current_user.email,
          description: current_user.name
        )

        StatsD.increment("troupeit.billing.customer.create")
        current_user.stripe_customer_id = customer.id.to_s
        current_user.save
      else
        # existing customer
        customer = Stripe::Customer.retrieve(current_user.stripe_customer_id)
        customer.card = token
        customer.save
      end

      charge = Stripe::Charge.create(
        amount: @app.get_current_price(),
        currency: "usd",
        customer: customer.id,  # note use of customer here instead of source
        description: "BHOF Application Fee",
        metadata: { "application_id" => @app.id.to_s }
      )

      @app.stripe_customer_id = customer.id.to_s
      @app.purchase_ip = request.remote_ip
      @app.purchased_at = Time.now
      @app.purchase_price = @app.get_current_price()
      @app.save

      StatsD.increment("troupeit.billing.apps.create")

      flash[:notice] = "Thank you for your payment! Your application has been updated."

      # TODO: nicer thank-you page
      respond_to do |format|
        format.json { render json: { errors: "OK", transstatus: "Charged", status: 200 }, status: 200 }
      end

      return
    rescue Stripe::CardError => e
      flash[:alert] = "We're sorry, Your card was declined, please try again."
      StatsD.increment("troupeit.billing.declined")
      respond_to do |format|
        format.json { render json: { errors: "Declined", transstatus: "declined", status: 200 }, status: 200 }
      end
      return
    end

    redirect_to dashboard_app_path(@app)
  end


  private

    # Use callbacks to share common setup or constraints between actions.
    def set_app
      begin
        @app = App.find(params[:id])
      rescue Mongoid::Errors::DocumentNotFound
        redirect_to apps_path, alert: "That application doesn't exist."
        false
      end
    end

    # Only allow a trusted parameter "white list" through.
    def app_params
      params.require(:app).permit(:legal_name, :mailing_address, :phone_primary, :phone_alt, :phone_primary_has_sms, :description, :legal_accepted, :locked, :forward_for_review, :final_decision, :sm_twitter, :sm_facebook, :sm_instagram)
    end

  def check_app_owner
    unless @app.user_id == current_user.id
      unless current_user.has_role?(:bhof_judge) or current_user.try(:admin?)
        redirect_to apps_path, alert: "You do not own that application."
        false
      end
    end
  end


  def abort_if_deadline
     if @deadline_passed
       redirect_to apps_path, alert: "The application deadline has passed. Modifications are no longer allowed."
       return false
     end

     true
  end

  def check_deadline_passed
    @deadline_passed = false

    if current_user.has_role?(:bhof_no_deadline)
      @deadline_passed = false
      return
    end

    if DateTime.now >= ::BHOF_FINAL_DEADLINE and current_user.has_role?(:bhof_judge) == false
      @deadline_passed = true
      nil
    end
  end

  def check_bhof_judge_or_scorer
    unless current_user.has_role?(:bhof_judge) or current_user.has_role?(:bhof_scorer)
      redirect_to "/", alert: "That feature is reserved for judges only."
      false
    end
  end

  def check_bhof_judge
    unless current_user.has_role?(:bhof_judge)
      redirect_to "/", alert: "That feature is reserved for judges only."
      false
    end
  end

  def get_current_round
    @round = Decider.where({ key: "bhof_round" })[0].value_f.to_i
  end

  def check_edit_allowed
    # You can only get the edit form or POST an update if the app has not been submitted or if you are a judge.
    if current_user.has_role?(:bhof_judge)
      return true
    end

    if @app.locked
      redirect_to dashboard_app_path(@app), alert: "This application has been submitted and may not be edited."
      false
    end
  end

  def find_next_id
    # next id is "next in this category"
    apps = App.where({ locked: 1, event_code: ::BHOF_EVENTCODE })
    temphash = Hash.new
    found = false
    @nextid = nil
    if params[:sort].present? and params[:dir].present?
      sortkey = params[:sort] + "|" + params[:dir]
    else
      sortkey = "default"
    end

    sorted = Rails.cache.fetch("app-next-#{sortkey}",  race_condition_ttl: 10, expires_in: 1.hours) do
      # iterate through all apps and attach the name, because this is always by name...
      apps.each { |a|
        # user, type, category, performername, description, status, round1/2/3 scores, actions

        begin
          case params[:sort]
          when "category"
              temphash[a.id.to_s] = a.entry.category.nil? ? 0 : a.entry.category
          when "type"
              temphash[a.id.to_s] = a.entry.type
          when "user"
              temphash[a.id.to_s] = a.user.username
          when "performername"
              temphash[a.id.to_s] = a.entry.name
          when "description"
              temphash[a.id.to_s] = a.description
          when "status"
              temphash[a.id.to_s] = a.status
          else
              temphash[a.id.to_s] = -1
          end
        rescue
          temphash[a.id.to_s] = -1
        end
      }

      temphash.sort_by { |key, value|  value }
    end

    sorted.each { |key, value|
      if found == true
        @nextid = key
        return
      end

      if key == @app.id.to_s
        found = true
      end
    }
  end

  def calc_stats(thisapp, reviews)
    # calculate app scores based on a mongoid collection of Bhofreviews
    # for a given application. Requires that @userscores exist and is a
    # hash

    rstat = Hash.new

    rstat["min"] = nil
    rstat["max"] = nil
    rstat["norm"] = 0.0
    rstat["median"] = nil
    rstat["avg"] = 0.0
    rstat["accepted"] = 0

    if reviews.count > 0
       @scores = reviews
    else
       @scores = nil
       return rstat
    end

    avg = nil
    tot = 0

    if reviews.count > 0
      reviews.each { |r|
        if r.recused == false
          if rstat["max"].nil? or r.score > rstat["max"]
            rstat["max"] = r.score
          end

          if rstat["min"].nil? or r.score < rstat["min"]
            rstat["min"] = r.score
          end

          tot = tot + r.score
          rstat["accepted"] += 1
        end
      }
      if rstat["accepted"] > 0
        avg = tot / rstat["accepted"]
        if rstat["accepted"] > 3
          norm = (tot - rstat["max"] - rstat["min"]) / (rstat["accepted"]-2)
        else
          norm = avg
        end
      end
    end

    rstat["avg"] = avg.nil? ? 0.0 : avg
    rstat["norm"] = norm.nil? ? 0.0 : norm
    rstat["norm_s"] = norm.nil? ? "" : sprintf("%.02f", rstat["norm"])
    rstat["avg_s"] = avg.nil? ? "" : sprintf("%.02f", avg)
    rstat["min_s"] = rstat["min"].nil? ? "" : sprintf("%.02f", rstat["min"])
    rstat["max_s"] = rstat["max"].nil? ? "" : sprintf("%.02f", rstat["max"])

    rstat
  end

  def check_scoring_closed
     if DECIDER("bhof_scores_close") > 0
       @scores_closed = true
     else
       @scores_closed = false
     end
  end

  def check_bhof_member
    if current_user.bhof_member_id.blank?
      redirect_to "/bhof/page1", flash: { error: "You must verify your BHOF membership to continue." }
    end
  end
end
