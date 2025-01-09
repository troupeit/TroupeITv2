class NotificationsController < ApplicationController
  protect_from_forgery
  before_action :authenticate_user!

  def index
    # use the user supplied limit if any
    @maxhistory = 5
    if params[:maxhistory].present?
      @maxhistory=params[:maxhistory].to_i
    end

    if @maxhistory > 100
      @maxhistory = 100
    end

    if @maxhistory == 0 or @maxhistory < 5
      @maxhistory = 5
    end

    @membercomp = CompanyMembership.where(user_id: current_user.id)

    # Yourself and anyone else in your companies...
    @cohorts = CompanyMembership.in(company_id: @membercomp.map(&:company_id))

    @activities = PublicActivity::Activity.any_in(owner_id: @cohorts.collect(&:user_id))
      .order(created_at: :desc)
      .limit(@maxhistory)

    # this is actually pretty tricky. for each event we have to
    # determine type, what happened, and return the appropriate set of
    # json data.

    # deletes are also a special case in that we must retain the old
    # description or title when something goes away so we can talk
    # about it, instead of just saying 'something' was deleted.

    json = Jbuilder.new do |j|
      j.activities @activities do |activity|
        j.activity activity

        # if we have the user, display it.
        if activity.owner_type == "User"
          @user = User.find(activity.owner_id)
          j.owner @user
        end

        begin
            # if this isn't a delete, we'll go ahead and fetch the old object
            # and return that with this record.
            case activity.trackable_type
            when "Act"
              @act = Act.find(activity._id)
              j.act @act
            when "CompanyMembership"
              @company_membership = CompanyMembership.find(activity.trackable_id)
              j.company_membership @company_membership
            when "Event"
              @event = Event.find(activity.trackable_id)
              j.event @event
            when "EventSubmission"
              @event_submission = EventSubmission.find(activity.trackable_id)
              j.event_submission @event_submision
            when "Passet"
              @passet = Passet.find(activity.trackable_id)
              j.passet @passet
            when "Task"
              # There's a strange bug here thanks to parameter security.
              # during updates, the event_id is null because we block
              # params updates of the event_id, so if this is an update
              # we have to use the event data from the task itself.
              if activity.parameters[:event_id].present?
                @event = Event.find(activity.parameters[:event_id])
                j.event @event
              else
                @task = Task.find(activity.trackable_id)
                @event = @task.event
                j.task @task
                j.event @event
              end
            when "Show"
              @show = Show.find(activity.trackable_id)
              j.event @show.event
              j.show @show
            when "ShowItem"
              if not activity.key.end_with?("destroy")
                @show_item = ShowItem.find(activity.trackable_id)
                j.show_item @show_item
                j.show @show_item.show
                j.event @show_item.show.event
              else
                # TODO: Better way of tracking double-deletes
                # if the item is gone and the show is gone, then we'll
                # throw an exception here.

                @show = Show.find(activity.parameters[:show])
                j.show @show
                j.event @show.event
              end

            end
        rescue Mongoid::Errors::DocumentNotFound
          # record is gone. oh well.
        end
      end
    end.target!

    respond_to do |format|
      format.json { render json: json }
    end
  end

  def history
  end
end
