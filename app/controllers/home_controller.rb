class HomeController < ApplicationController
  def index
    # parameter "l" is "landing page force". We use this for the links on /bhof
    # and when we want to show the brochure-ware.

    if user_signed_in? and DECIDER("dashboard_enable") > 0 and params[:l].blank?
      render "dashboard", layout: "application"
    else
       render layout: "home"
    end
  end
end
