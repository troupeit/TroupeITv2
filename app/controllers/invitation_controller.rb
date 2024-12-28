class InvitationController < ApplicationController
protect_from_forgery

before_action :authenticate_user!

def index
  # get all of the pending invites for a particular user to allow for retractions, etc.
  begin
    @invites = Invitation.where(sender: current_user)
  rescue Mongoid::Errors::DocumentNotFound
    @invites = nil
  end
end

def create
  @sent = 0
  if not params[:invitation][:email].present? or not params[:invitation][:company_id].present?
    respond_to do |format|
      format.html { head :unprocessable_entity }
      format.json { render json: { "error" => "unprocessable" } }
    end
    return
  end

  @company = Company.find(params[:invitation][:company_id])
  if not @company.user_can_invite?(current_user)
    respond_to do |format|
      format.html { head :forbidden }
      format.json { render json: { "error" => "current user is not allowed to invite." } }
    end
    return
  end

  email_addresses = params[:invitation][:email].scan(/([a-z0-9_.-]+@[a-z0-9_-]+\.[a-z]+)/i)

  email_addresses.each { |e|
    @invitation = Invitation.new
    @invitation.company_id = @company.id.to_s
    @invitation.email = e[0]
    @invitation.used = false
    @invitation.sender = current_user
    @invitation.access_level = 0
    if @invitation.save
      CompanyMailer.invitation(current_user, @invitation, @company).deliver
      @sent += 1
    end
  }

  respond_to do |format|
    format.html { head :ok }
    format.json { render json: { "status" => "ok", "sent" => @sent } }
  end
end

def accept
  # we have two invite types: A general "anyone can join" URL and
  # direct invites that grant more access. Try the general invite
  # first then the direct, by-email invite second.

  begin
    @i = Invitation.find_by(token: params[:id])
    @company_for_invite = Company.find(@i.company_id)
  rescue
      redirect_to "/", alert: "Invalid invitation code."
      return Mongoid::Errors::DocumentNotFound
  end

  # verify if used and then kill the invite code
  if @i.present?
    if @i.valid_until.present?
      if @i.valid_until <= DateTime.now
        redirect_to "/companies/", alert: "That invitation code has expired."
        return
      end
    end

    if @i.used
      redirect_to "/companies/", alert: "That invitation code has already been used."
      return
    end

    # non-atomic, but very low velocity, should be ok.
    @i.use_count = @i.use_count + 1
    if @i.single_use
      @i.used = true
    end

    @i.save

  end

  # are you already a member?
  current_user.company_memberships.each { |tm|
    if tm.company_id.present? and tm.company_id.to_s == @company_for_invite._id.to_s
      if @i.nil?
        redirect_to "/", alert: "You are already a member of \"#{@company_for_invite.name}\"."
        return
      end

      if tm.access_level == @i.access_level
        redirect_to "/", alert: "You are already a member of \"#{@company_for_invite.name}\"."
        return
      else
        # access level upgrade / downgrade
        if @i.access_level > tm.access_level
          tm.access_level = @i.access_level
          if tm.save
            redirect_to "/", notice: "You hvae been upgraded to #{CMACCESS[@i.access_level]} in company \"#{@company_for_invite.name}\"."
            return
          else
            redirect_to "/", alert: "We were unable to modify your account with this invitation."
            return
          end
        else
          redirect_to "/", alert: "The invitation was for a lower access level than yours and was ignored."
          return
        end

      end
    end
  }

  # are you the owner?
  if @company_for_invite.user_id == current_user.id
    redirect_to "/companies/", alert: "You are already the owner of \"#{@company_for_invite.name}\"."
    return
  end

  @crew_count = CompanyMembership.where({ company: @company_for_invite }).gte(access_level: 2).count
  if @company_for_invite.subscription_plan.nil?
    @current_plan = SubscriptionPlan.find_by(stripe_id: "FREE")
  else
    @current_plan = @company_for_invite.subscription_plan
  end

  if @crew_count >= @current_plan.crew_size and @current_plan.crew_size != -1 and @i.access_level > CM_PERFORMER
    redirect_to "/", alert: "We're sorry, \"#{@company_for_invite.name}\" has exceeded it's crew size. Please ask the company owner to upgrade their TroupeIT subscription."
    logger.info "Subscription size exceeded for #{@current_plan.name} plan, company #{@company_for_invite.name} - #{@company_for_invite.id}"
    return
  end

  # All good - add the user to the company
  tm = CompanyMembership.new
  tm.user = current_user
  tm.company = @company_for_invite
  if @i.present?
    tm.access_level = @i.access_level
  end
  tm.sort_name = current_user.name.upcase
  tm.sort_username = current_user.name.upcase
  tm.save

  redirect_to "/", alert: "You are now a member of \"#{@company_for_invite.name}\" with #{CMACCESS[@i.access_level]} access."
end
end
