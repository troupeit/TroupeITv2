class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :build_company_select, only: [ :show, :edit, :new, :create ]
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :showpage, :live ]

  protect_from_forgery

  # GET /events/id/submissions.json
  def submissions
    # return all submissions for a specific event id
    @es = EventSubmission.where(event_id: params[:id])

    # SECURITY: check if user is owner here?
    respond_to do |format|
      format.html { render nothing: true,  status: 400 }
      format.json { render json: @es.to_json(include: [ :act, :user ]) }
    end
  end

  # GET /events/id/tasks.json
  def tasks
    # return all submissions for a specific event id
    @t = Task.where(event_id: params[:id]).order_by(:seq)

    # SECURITY: check if user is owner here?
    respond_to do |format|
      format.html { render nothing: true,  status: 400 }
      format.json { render json: @t.to_json }
    end
  end

  def accepting_submissions
    # return all events accepting submissions for the current user's id.
    # does not include publically accepting companies (by design)
    @accepting = SubmissionTools.get_events_accepting(current_user)

    # SECURITY: check if user is owner here?
    respond_to do |format|
      format.html { render nothing: true,  status: 400 }
      format.json { render json: @accepting.to_json({ include: :company }) }
    end
  end

  # GET /events
  def index
    if not params[:company].present? or params["company"] == "all"
      @membercomp = CompanyMembership.where(user_id: current_user.id)
    else
      @membercomp = CompanyMembership.where(company_id: params[:company])
    end

    # this will never be all companies in the system. You have to be a member of a company to see any shows at all.
    @events = Event.in(company_id: @membercomp.map(&:company_id)).order_by(startdate: "asc")

    respond_to do |format|
      format.html { render action: "index" }
      format.json { render json: @events.to_json(include: [ :company, :shows ]) }
    end
  end

  # GET /events/1
  def show
    # for each act return a set of asset id to pasest objs.
    # for each show
    #   for each show item
    #      for each asset
    #          somehash <<  (assetid, passet object)
    #
    # @somehash as json

    if @event.nil?
      flash[:alert] = "That event does not exist."
      redirect_to "/"
    end

    @passets = {}

    @event.shows.each { |es|
      es.show_items.each { |si|
        if si.kind == ShowItem::KIND_ASSET
          if si.act.present?
            si.act.act_asset.each { |sia|
              @passets[sia.passet._id.to_s] = sia.passet
            }
          end
        end
      }
    }

    showsobj = []
    @event.shows.each do |s|
      siarr = []
      s.show_items.each do |si|
        owner = ""
        if si.act.present?
          owner = { name: si.act.user.name, username: si.act.user.username, id: si.act.user._id.to_s }
        end

        siarr << { show_item: si,
                   act: si.act,
                   owner: owner,
                   assets: si.act.present? ? si.act.act_asset : nil,
                   note_personal: si.get_note(current_user, ShowItemNote::KIND_PRIVATE),
                   note_company:  si.get_note(current_user, ShowItemNote::KIND_COMPANY)
        }
      end
      showsobj << { show: s, show_items: siarr }
    end

    obj = { event: @event, shows: showsobj, company: @event.company, passets: @passets, tasks: @event.tasks.order_by(seq: "asc") }

    respond_to do |format|
      format.html { render action: "index" }

      format.json {
        # Render the event and all of it's subitems
        # trying to get around jbuilder and do this iteratively
        json = obj.to_json

        render json: json
      }
    end
  end

  def showpage
    if not @event.present?
      redirect_to "/", alert: "The requested event does not exist."
    end
  end

  # GET /events/new
  def new
    @event = Event.new
    @membercomp = CompanyMembership.where(user_id: current_user.id)
  end

  # GET /events/1/edit
  def edit
    @membercomp = CompanyMembership.where(user_id: current_user.id)
  end

  def live
    @show = @event.shows.first

    redirect_to live_show_path(@show)
  end

  # POST /events
  def create
    @event = Event.new(event_params)
    @event.company = Company.find(event_params[:company])

    if @event.save
      StatsD.increment("troupeit.events.create")
      respond_to do |format|
        format.html { redirect_to @event, notice: "Event was successfully created." }
        format.json { render json: @event.to_json(include: [ :company ]) }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { errors: @event.errors.full_messages, status: 422 }, status: 422 }
      end
    end
  end

  # PATCH/PUT /events/1
  def update
    if @event.update(event_params)
      StatsD.increment("troupeit.events.update")
      respond_to do |format|
        format.html { redirect_to events_url, notice: "Event was successfully updated." }
        format.json { render json: { errors: "None", status: 200 }, status: 200 }
      end
    else
      respond_to do |format|
        format.html { render :edit, error: "Event could not be updated." }
        format.json { render json: { errors: @event.errors.full_messages, status: 422 }, status: 422 }
      end
    end
  end

  # DELETE /events/1
  def destroy
    if @event.destroy
      StatsD.increment("troupeit.events.destroy")
      respond_to do |format|
        format.html { redirect_to events_url, notice: "Event was successfully destroyed." }
        format.json { render json: { errors: "None", status: 200 }, status: 200 }
      end
    else
      respond_to do |format|
        format.html { redirect_to events_url, error: "Event could not be deleted." }
        format.json { render json: { errors: @event.errors.full_messages, status: 422 }, status: 422 }
      end
    end
  end

  def build_company_select
    @companysel = Hash.new

    memberships = CompanyMembership.where(user_id: current_user.id)
    memberships.each { | m |
      @companysel[m.company.name] = m.company._id
    }
  end

  private

  def set_event
    begin
      @event = Event.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      @event = nil
    end

    if @event.nil?
      # SECURITY: check if user is owner here?
      respond_to do |format|
        format.html { redirect_to "/", alert: "The selected event does not exist." }
        format.json { render json: { errors: "Not Found", status: 404 }, status: 404 }
      end

      @event
    end
  end

  # Only allow a trusted parameter "white list" through.
  def event_params
    params.require(:event).permit(:title, :time_zone, :startdate, :enddate, :company, :motd, :accepting_from, :submission_deadline)
  end
end
