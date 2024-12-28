# true/false monkeypatch - I had to add this again for this class, no idea why.
require "#{Rails.root}/lib/yesno.rb"

include ActionView::Helpers::NumberHelper

class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :must_be_admin, only: [ :become, :index, :update, :destroy, :undelete ]

  def become
    # Oh, hello old friend. We had this feature at Twitter and it was
    # damn useful for debugging, albeit scary for privacy.
    #
    # in the future we may consider https://github.com/flyerhzm/switch_user gem

    # bypass stops us from updating their last login / IP address
    begin
      u = User.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to root_url, notice: "The requested user does not exist."
      return
    end

    logger.info("SECURITY: User #{current_user.username} (#{current_user._id}) became #{u.username} (#{u._id})")

    sign_in(:user, u, { bypass: true })
    redirect_to root_url # or user_root_url
  end

  def undelete
    # restore a deleted user

    begin
      u = User.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to root_url, notice: "The requested user does not exist."
      return
    end

    u.deleted_at = nil
    u.save

    logger.info("SECURITY: User #{current_user.username} (#{current_user._id}) undeleted #{u.username} (#{u._id})")

    flash[:notice] = "User restored."

    redirect_to user_path(u)
  end

  def me
    # get the current user and their account status.
    # we use this at login.
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

    respond_to do |format|
      format.html { }
      format.json { render json: { user: current_user,
                                      companies: { owned: @owned.count,
                                                      paid: @paid_companies
                                                    }
                                    }
      }
    end
  end

  def index
    @roles = Role.all
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json {
        # drive datatables
        @usersarray = []
        @users.each { |user|
          @usersarray << { "image" => user.profile_img_url("normal"),
                           "username" => user.username,
                           "email" => user.email,
                           "phone" => number_to_phone(user.phone_number),
                           "last_sign_in" => user.last_sign_in_at.strftime(SHORT_TIME_FMT),
                           "last_sign_in_ip" => user.last_sign_in_ip,
                           "actscount" => user.acts.count,
                           "provider" => user.provider,
                           "admin" => user.admin.yesno,
                           "id" => user.id.to_s,
                           "provider_uid" => user.uid }
        }
        render json: { "aaData" => @usersarray }
      }
    end
  end

  def show
    @roles = Role.all.asc(:name)

    begin
      @user = User.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to root_url, notice: "The requested user does not exist."
      return
    end

    begin
      @companies_owned = Company.where(user_id: @user._id)
    rescue Mongoid::Errors::DocumentNotFound
      @companies_owned = nil
    end

    @companies = CompanyMembership.where(user_id: @user._id)

    logger.info("SECURITY: User #{current_user.username} (#{current_user._id}) viewed #{@user.username} (#{@user._id})")

    if current_user.try(:admin?)
      respond_to do |format|
        format.html { render :show }
        format.json { render json: { user: @user }  }
      end
    else
      # if you're not an admin, we restrict fields.
      allowed_user_data = [ :_id,
                          :uid,
                          :name,
                          :avatar_uuid,
                          :created_at,
                          :cover_uuid,
                          :avatar_uuid,
                          :location,
                          :miniresume
                         ]


      if CompanyMembership.is_cohort?(current_user, @user)
        if @user.share_email
          allowed_user_data << :email
        end

        if @user.share_phone
          allowed_user_data << :phone_number
        end
      end

      respond_to do |format|
        format.html { render :show }
        format.json { render json: @user.as_json(root: true,
                                                    only: allowed_user_data) }
      end
    end
  end

  def update
    begin
      @user = User.find(params[:id])
      @user.update_attributes(user_params)

    rescue Mongoid::Errors::DocumentNotFound
      redirect_to root_url, notice: "The requested user does not exist."
      return
    end


    # This is the only time we permit the admin bit to be flipped.
    # you must be an admin first and we have to set this locally due
    # to mass assignment protection.

    if params[:user][:admin] == "1" then
       @user.admin = true
    else
       @user.admin = false
    end

    # update roles
    @user.roles = nil

    if params[:role_r].present?
      params[:role_r].each do |p|
        begin
          @user.roles << Role.where(id: p)
        rescue Mongoid::Errors::DocumentNotFound
          flash[:alert] = "User update failed - invalid role specified."
          redirect_to "/users"
          return
        end
      end
    end

    logger.info("SECURITY: User #{current_user.username} (#{current_user._id}) modified #{@user.username} (#{@user._id})")

    @user.save
    StatsD.increment("troupeit.user.update")

    if params[:user][:password].present? and params[:user][:password_confirmation]
      if @user.reset_password(params[:user][:password], params[:user][:password_confirmation])
        flash[:notice] = "User update and password change successful."
      else
        flash[:error] = "User Updated, but password Change failed (too short?)"
      end
      redirect_to "/users/#{@user._id}"
      return
    end

    flash[:notice] = "User Updated."
    redirect_to "/users/#{@user._id}"
  end

  def destroy
    begin
      @user = User.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to users_url, alert: "The requested user doesn't exist."
      return
    end

    @user.destroy

    if @user.destroy
      redirect_to users_url, notice: "User #{@user.username} (#{@user.name}) deleted."
      StatsD.increment("troupeit.user.destroy")
    end
  end

  def company_memberships
    @user = User.find(params[:id])
    @cms = @user.company_memberships

    respond_to do |format|
      format.html { render action: "index" }
      format.json { render json: @cms.to_json(include: { company: { include: :user } }) }
    end
  end

  def recent_acts
    @user = User.find(params[:id])
    @acts = @user.acts

    respond_to do |format|
      format.html { render action: "index" }
      format.json { render json: { acts: @acts } }
    end
  end

  def recent_shows
    @user = User.find(params[:id])
    @shows = ShowItem.in(act_id: @user.acts.map(&:id)).uniq { |x| x.show_id }

    respond_to do |format|
      format.html { render action: "index" }
      format.json { render json: @shows.to_json(include: { show: { include: { event: { include: :company, except: [ :stripe_subscription_id, :stripe_customer_id, :paid_through, :invite_code ] } } } }) }
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :username, :email, :password, :password_confirmation, :remember_me, :used_invite, :disable_tutorial, :cover_uuid, :avatar_uuid, :phone_number, :time_zone, :sms_sleep_start, :sms_sleep_end, :location, :miniresume, :live_view_columnpref)
  end

  def must_be_admin
   if ! current_user.try(:admin?)
     flash[:alert] = "You must be an administrator to use that function."
     redirect_to "/"
   end
  end
end
