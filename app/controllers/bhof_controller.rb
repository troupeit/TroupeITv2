class BhofController < ApplicationController
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
    dbmember = BhofMember.any_of({ email: searchid },
                                 { memberid: searchid.to_i }).first

    if dbmember.present?
      # got db match, use it
      @memberstate = dbmember.membership_status
      @memberemail = dbmember.email
      @memberid    = dbmember.memberid
      @error       = nil

      if @memberstate != "Active"
        # give them another try through WA if not active
        @memberid = wa_lookup(searchid)
        StatsD.increment("troupeit.bhof.verification.used_wa_api")
      else
        StatsD.increment("troupeit.bhof.verification.active_in_db")
      end
    else
      @memberid = wa_lookup(searchid)
      StatsD.increment("troupeit.bhof.verification.used_wa_api")
    end

    # are you active now?
    if @memberstate != "Active"
      @error = "Membership found but it is not current. Please renew your membership, or if you have already renewed, try again later."
      StatsD.increment("troupeit.bhof.verification.fail.expired")
    end

    if @memberid.present?
      # is anyone else using this?
      u = User.where({ bhof_member_id: @memberid })
      if u.count > 0 and @memberid != current_user.bhof_member_id
        @error = "That BHOF membership is already in use by another TroupeIT user"
        StatsD.increment("troupeit.bhof.verification.fail.email_inuse")
      else
        if current_user.email != @memberemail
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

  def wa_lookup(searchid)
    # return a valid member ID based on member ID number or email address
    # return nil if invalid
    #
    # Sets instancevars: @memberstate, @memberemail, returns memberid

    @member = nil
    @error = nil

    Pluot.account_id = Rails.application.credentials.wa_account_id
    Pluot.api_key = Rails.application.credentials.wa_api_key

    if searchid.to_i > 0
      if searchid.length == 8
        @member = Pluot.contacts.filter("id eq #{searchid}")
      else
        @error = "Invalid member ID"
        StatsD.increment("troupeit.bhof.verification.fail.invalid_member_id")
      end
    else
      if valid_email?(params[:bhofmember][:memberid])
        @member = Pluot.contacts.filter("e-mail eq #{searchid}")
      end
    end

    begin
      if not @member.blank? and @member.has_key?(:Contacts) and @member[:Contacts].size > 0
        @memberstate = @member[:Contacts][0][:Status]
        @memberemail = @member[:Contacts][0][:Email]
        return @member[:Contacts][0][:Id]
      end
    rescue NoMethodError
      # sometimes the API returns a nonsense string.
      @error = "Error communicating with membership server. Please try again later."
      # what the hell is going on here.
      logger.info("ERROR: Got strange response from WA API")
      logger.info(@member)
      StatsD.increment("troupeit.bhof.verification.fail.exception_raised")
      return nil
    end


    nil
  end
end
