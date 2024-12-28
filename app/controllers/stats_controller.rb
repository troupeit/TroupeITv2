class StatsController < ApplicationController
  # Return statistics about the application for use in dashboards

  before_action :set_cache_buster

  def index
    stats = Hash.new
    stats["users"] = User.all.count
    stats["acts"] = Act.all.count
    stats["events"] = Event.all.count
    stats["apps"] = App.all.count
    stats["companies"] = Company.all.count
    stats["assets"] = Passet.all.count
    stats["shows"] = Show.all.count
    stats["reviews"] = Bhofreview.all.count
    stats["event_submissions"] = EventSubmission.all.count
    stats["invitations"] = Invitation.all.count
    stats["actspershow"] = (stats["acts"] / stats["shows"])

    respond_to do |format|
      format.html { raise ActionController::RoutingError.new("Not Found") }
      format.json { render json: stats }
     end
  end
end
