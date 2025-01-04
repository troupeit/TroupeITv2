class BhofController < ApplicationController
  include ApplicationHelper

  before_action :authenticate_user!, except: [ :index, :show ]

  # these pages exist in /show
  ALLOWED_PAGES=[ "rules", "judging_criteria", "page1", "page2", "page3", "membership" ]

  # but these pages require authentication...
  AUTHED_PAGES=[ "page1", "page2", "page3", "membership" ]

  def show
    # whitelist acceptable pages here. This controller serves primarily static pages.

    if ALLOWED_PAGES.include?(params[:id])
      if AUTHED_PAGES.include?(params[:id])
        authenticate_user!
      end

      # if you are asking for page1, and you're already verified, jump to page2.
      if current_user.present?
        if current_user.bhof_member_id.present? and params[:id] == "page1"
          StatsD.increment("troupeit.bhof.hits.user_already_verified")
          redirect_to "/bhof/page2"
          return
        end
      end

      if params[:id] == "page1"
        # if you are here, you are starting verification again
        StatsD.increment("troupeit.bhof.hits.request_user_verify")
      end

      render params[:id]
    else
      redirect_to "/404.html"
    end
  end

  def verify
    if params[:bhofmember][:memberid].blank?
      flash[:alert] = "You must enter your member ID or email address"
      redirect_to "/bhof/page1"
      return
    end

    @memberid = nil
    searchid = params[:bhofmember][:memberid].strip
    dbmember = BhofMember.any_of({ email: searchid }, { memberid: searchid }).first

    if dbmember.present?
      logger.info "bhofmember: found cached db entry for #{searchid}"
      # got db match, use it
      @memberstate = dbmember.membership_status
      @memberemail = dbmember.email
      @memberid    = dbmember.memberid
      @error       = nil
      StatsD.increment("troupeit.bhof.verification.active_in_db")

      # are you active now?
      if @memberstate != "100" and @memberstate != "75"
         @error = "Membership found but it is not current. Please renew your membership, or if you have already renewed, try again later."
         StatsD.increment("troupeit.bhof.verification.fail.expired")
         logger.info "bhofmember: #{searchid} membership not current"
      end
    else
      logger.info "bhofmember: trying API for #{searchid}"

      # one last try, let's attempt to hit the API directly (by email)
      member = JoinIt.get_user(searchid)
      logger.info "bhofmember: API lookup returns #{member.count} records"
      if JoinIt.is_valid(member)
        @error = nil
        @memberid = member[0]["members_id"]
      else
        logger.info "bhofmember: API returns not valid #{searchid}"
        @error = "Membership not found. If you have just renewed your membership, please wait and try again in two hours."
      end
    end

    # is the membership in good standing?
    if @memberid.present?
      # is anyone else using this?
      u = User.where({ bhof_member_id: @memberid })

      if u.count > 0 and @memberid != current_user.bhof_member_id
        logger.info "bhofmember: #{searchid} already in use by #{u.id}"

        @error = "That BHOF membership is already in use by another TroupeIT user"
        StatsD.increment("troupeit.bhof.verification.fail.email_inuse")
      else
        if current_user.email != @memberemail
          logger.info "bhofmember: #{searchid} email mismatch #{current_user.email} != #{@memberemail}"
          @error =  "Your TroupeIT E-Mail address does not match your BHOF address. Please update your TroupeIT email address."
          StatsD.increment("troupeit.bhof.verification.fail.email_mismatch")
        end
      end
    end

    if @error.blank?
      # stash it away
      current_user.bhof_member_id = @memberid
      current_user.save

      flash[:notice] = "Membership verified (BHOF ID #{current_user.bhof_member_id})"
      StatsD.increment("troupeit.bhof.verification.succeeded")
      logger.info "bhofmember: #{searchid} verified!"

      redirect_to "/bhof/page2"
      return
    end

    flash[:alert] = @error
    StatsD.increment("troupeit.bhof.verification.failed")
    render "page1"
  end

  def index
    # first page does not require authentication
    StatsD.increment("troupeit.bhof.hits.frontdoor")
    render "page0"
  end

  private

  def valid_email?(email)
    email_regex = %r{\A\S+@.+\.\S+\z}
    (email =~ email_regex)
  end
end
