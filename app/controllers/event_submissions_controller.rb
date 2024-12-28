class EventSubmissionsController < ApplicationController
  # simple controller to handle new submissions

  before_action :authenticate_user!
  before_action :set_event, only: [ :update, :destroy ]

  def create
    @es = EventSubmission.new(eventsubmission_params)
    @es.user = current_user

    # are we accepting?
    @event = Event.find(eventsubmission_params[:event_id])
    if @event.accepting_from == 0
      respond_to do |format|
        format.html { render nothing: true,  status: 403 }
        format.json { render json: { errors: "Submissions are not open for this event." }, status: 403 }
      end
      return
    end

    # these will throw exceptions if they don't exist.
    @es.act = Act.find(eventsubmission_params[:act_id])
    @es.event = @event

    # check for duplicate and error out if so.
    @existing = EventSubmission.where({ act_id: @es.act.id, event_id: @es.event.id })
    if @existing.count > 0
      logger.debug "submission already exists"

      respond_to do |format|
        format.html { render nothing: true,  status: 409 }
        format.json { render json: { errors: "Submission already exists." }, status: 409 }
      end
      return
    end

    if @es.save
      respond_to do |format|
        format.html { render nothing: true,  status: 400 }
        format.json { render json: @es.to_json() }
      end
    else
      respond_to do |format|
        format.html { render nothing: true,  status: 400 }
        format.json { render json: { errors: "Unprocessable submission." }, status: 422 }
      end
    end
  end


  def update
    if @es.update_attributes(eventsubmission_params)
      # Handle a successful update.
      respond_to do |format|
        format.html { render nothing: true,  status: 200 }
        format.json { render json: { errors: "Update OK." }, status: 200 }
      end
    else
      respond_to do |format|
        format.html { render nothing: true,  status: 422 }
        format.json { render json: { errors: "Update failed." }, status: 422 }
      end
    end
  end

  def destroy
    @es.destroy

    respond_to do |format|
      format.html { render nothing: true,  status: 200 }
      format.json { render json: { errors: "Deleted." }, status: 200 }
    end
  end

  private

  def set_event
    # TODO: SECURITY CHECK?
    # Can only manipulate ES if submission is part of a show that you own?
    begin
      @es = EventSubmission.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      respond_to do |format|
        format.html { render nothing: true,  status: 404 }
        format.json { render json: { errors: "Not Found" }, status: 404 }
      end
      nil
    end
  end

  def eventsubmission_params
    params.require(:event_submission).permit(:event_id, :act_id, :is_alternate)
  end
end
