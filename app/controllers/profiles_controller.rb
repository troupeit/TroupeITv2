class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def company
    # this drives the profile page
    @coverurl = ActionController::Base.helpers.asset_path("default_cover_image.jpg")
    expanded = params[:id].gsub("_", " ")
    @companies = Company.where(name: /^#{expanded}$/i)

    if @companies.count == 0
      begin
        @company = Company.find(params[:id])
      rescue
        redirect_to root_url, notice: "The requested company does not exist."
        nil
      end
    else
      @company = @companies[0]
    end
  end

  def show
    # this drives the profile page - we'll accept username here (with
    # underscores instead of spaces, or an actual id.
    @coverurl = ActionController::Base.helpers.asset_path("default_cover_image.jpg")
    expanded = params[:id].gsub("_", " ")
    @users = User.where(username: /^#{expanded}$/i)
    if @users.count == 0
      begin
        @user = User.find(params[:id])
      rescue
        redirect_to root_url, notice: "The requested user does not exist."
        nil
      end
    else
      @user = @users[0]
    end
  end
end
