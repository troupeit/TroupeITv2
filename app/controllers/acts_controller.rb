class ActsController < ApplicationController
  include ApplicationHelper

  protect_from_forgery

  before_action :authenticate_user!
  before_action :set_cache_buster
  before_action :validate_return
  before_action :length_to_seconds, only: [ :update, :create ]

  # GET /acts
  # GET /acts.json
  def index
    # TODO: This routine breaks if you request /acts/self.  The logic
    #       is inverted and needs help.  admin access should not
    #       change this thing's output. admin should be moved to
    #       /adminindex or similar

    if params[:company_id].present? and params[:company_id] != "undefined"
      # if you supply a company ID, we'll find all the acts for all the people in that company.
      # but, you have to be a member of that company.
      @membercomp = CompanyMembership.where({ user_id: current_user.id, company_id: params[:company_id] })[0]
      if @membercomp.nil?
        flash[:alert] = "You are not a member of that company."
        redirect_to "/"
        return
      end

      if @membercomp.access_level < CM_STAGEMGR
        flash[:alert] = "Insufficent access. Stage manager (or higher) required."
        redirect_to "/"
        return
      end

      @cohorts = CompanyMembership.where(company_id: params[:company_id])
      @acts = Act.in(user_id: @cohorts.map(:user_id))
    else
      logger.info "acts: loading for non admin or self"
      logger.info current_user.acts
      @acts = current_user.acts.order_by(updated_at: "desc")
    end

    @actarray = []
    json_tag = "aaData"

    if request.format.json?
        # this format is used to drive the show editing page. It is a
        # digusting O(n) query. I do not care.  talk to me when we
        # have 100k users.
        @acts.each { |a|
          un = "<font color=#ff0000>Deleted User</font>"

          username = ""
          email = ""

          if a.user != nil
            username = a.user.name
            email = a.user.email
            un = username + "<br>" + email
          end

          # TODO: REFACTOR: REMOVE ALL OF THE TYPE1 TYPE2 CODE
          case params[:type].to_i
          when 3
            # type 3 is the 'new format' with proper json naming, used by json endpoints.
            json_tag="acts"
            @actarray << { id: a.id.to_s,
                           username: username,
                           email: email,
                           title: a.title,
                           stage_name:  a.stage_name,
                           short_description: a.short_description,
                           length: a.length,
                           created_at: a.created_at,
                           updated_at: a.updated_at
                         }
          when 2
            # type 2 is standard index. which shows the owner and edit/update buttons
            @actarray << [ a.updated_at, un, a.stage_name, a.short_description + " (" + TimeTools.sec_to_time(a.length) + ")",  "<a class=\"btn btn-sm btn-success\" href=\"/acts/#{a._id}/edit\" id=\"#{a._id}\"><i class=\"glyphicon glyphicon-pencil white\"></i> Edit</a>&nbsp;<a class=\"btn btn-sm btn-danger\" href=\"/acts/#{a._id}\" data-confirm=\"Are you sure?\" data-method=\"delete\" rel=\"nofollow\"><i class=\"glyphicon glyphicon-remove white\"></i> Delete</a>" ]
          else
            # type 1 is the add-to-showpage which shows an add button
            @actarray << [ a.updated_at, un, a.stage_name, a.short_description + " (" + TimeTools.sec_to_time(a.length) + ")", musicinfo, a.id.generation_time.getlocal.strftime(SHORT_TIME_FMT), "<button class=\"btn btn-success actadder\" id=\"#{a._id}\"><i class=\"glyphicon glyphicon-plus white\"></i> Add</button>" ]
          end
      }
    end

    respond_to do |format|
      format.html { render action: "index" }
      format.json { render json: { json_tag => @actarray  } }
    end
  end

  # GET /acts/1
  # GET /acts/1.json
  def show
    begin
      @act = Act.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      flash[:alert] = "That Act does not exist."
      redirect_to "/"
      return
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @act }
    end
  end

  # GET /acts/new
  # GET /acts/new.json
  def new
    @act = Act.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @act }
    end
  end

  # GET /acts/1/edit
  def edit
    begin
      @act = Act.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      flash[:alert] = "That Act does not exist."
      redirect_to "/"
      return
    end

    # First try... was this act submitted to a show that we are a stage manager in?
    edit_allowed = false

    @submitted_to = EventSubmission.where({ act_id: @act._id })
    @submitted_to.each { |s|
      @memberships = CompanyMembership.where({ user: current_user, company: s.event.company })
      @memberships.each { |m|
        if m.access_level >= CM_STAGEMGR
             edit_allowed = true
        end
      }
    }

    # Second try... Is the act inside of a show that we are stage manager in?
    if edit_allowed == false
      @in_shows = ShowItem.where({ act_id: @act._id })
      @in_shows.each { |s|
        @memberships = CompanyMembership.where({ user: current_user, company: s.show.event.company })
        @memberships.each { |m|
          if m.access_level >= CM_STAGEMGR
            edit_allowed = true
          end
        }
      }
    end

    if @act.user_id != current_user.id and current_user.try(:admin?) == false and edit_allowed == false
      flash[:alert] = "You don't own that Act."
      redirect_to "/"
    end

    @act.length = TimeTools.sec_to_time(@act.length)

    # map the passets (if any) into something that MultiFileSelect can
    # handle

    @passetmap = Array.new

    @act.act_asset.each { |ap|
      @passetmap << ap.passet
    }
  end

  # POST /acts
  # POST /acts.json
  def create
    @act = Act.new(act_params)

    respond_to do |format|
      if @act.save
        StatsD.increment("troupeit.acts.create")
        attach_passets
        current_user.acts << @act
        current_user.save!

        # if return_to is present, and we're actively building a show,
        # then add this newly created act into our show and showitem list

        if @return_to.present?
          if @return_to.include?("active_show")
            parts = CGI.parse(@return_to.split("?")[1])

            @show = Show.where({ id: parts["active_show"][0] }).find_one_and_update({ "$inc" => { showitem_seq: 1 } })
            if not @show.nil?
              @show_item = ShowItem.new
              @show_item.act = @act
              @show_item.show = @show
              @show_item.kind = ShowItem::KIND_ASSET
              @show_item.seq = @show.showitem_seq
              @show_item.duration = @act.length
              @show_item.save
            end
          end
        end

        format.html {
          if @return_to == "/"
            # mark the new creation in the session so we can prompt
            # the user, on the dashboard about submitting to a
            # show. We'll remove the cookie if there are no open shows
            # or if we successfully open the dialog.

            # if there are shows with open submissions, then...
            if SubmissionTools.get_events_accepting(current_user).length > 0
              cookies[:recent_act_created] = { value: @act.id.to_s, expires: 1.hour.from_now }
            end
          end

          redirect_to @return_to, notice: "Act was successfully created."
        }
        format.json { render json: @act, status: :created, location: @act }
      else
        # we've failed, so we need to reshow our form.

        @act.length = TimeTools.sec_to_time(@act.length)

        if @act.length == -1
          @act.length = nil
        end

        # pass this through if we can
        if params["passetids"].present?
          @passetmap = Array.new
          params["passetids"].keys.sort.each { |key|
            begin
              p = Passet.find(params["passetids"][key])
              @passetmap << p
            rescue Mongoid::Errors::DocumentNotFound
              # silently fail: somehow the passet went away between the
              # time that our form selection took place and now. We're
              # going to log that and move on.
              logger.info("New Act - Asset #{params["passetids"][key]} went away before it could be attached.")
            end
          }
        end

        format.html { render action: "new" }
        format.json { render json: @act.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /acts/1
  # PUT /acts/1.json
  def update
    @act = Act.find(params[:id])

    if params[:tags].is_a?(String)
      taglist = params[:tags].split(",")
    else
      taglist = []
    end

    respond_to do |format|
      if @act.update(act_params)
        StatsD.increment("troupeit.acts.update")
        # now update tags. user edits replace the user's tags.
        if @act.user.present?
          @act.user.tag(@act, taglist)
        end

        attach_passets

        # We always check to see if we have to update durations.  the
        # user could have changed the act length, and our durations
        # (in the show) would be wrong.
        #
        # Caveat: This will update the duration in all shows that
        # contain this act. Even if the show manager has changed the
        # act the "last" update of the act's information will always
        # take precedence.

        @sis_to_update = ShowItem.where(act_id: @act.id.to_s)
        @sis_to_update.each { |si|
          si.duration = @act.length
          si.save

          # we also have to mark the show as 'dirty'.
          # if someone changes their act the show has also been updated.
          si.show.updated_at = Time.now
          si.show.save
        }

        format.html {
          if @return_to != "/"
            redirect_to @return_to, notice: "Act was successfully updated."
            return
          end

          # if we have an event that is open for submission, then set this cookie..
          cookies[:try_submit] = { value: @act.id.to_s, expires: Time.now + 3600 }

          redirect_to "/", notice: "Act was successfully updated."
        }

        format.json { head :no_content }
      else
        # update failed
        @act.length = TimeTools.sec_to_time(@act.length)
        format.html { render action: "edit" }
        format.json { render json: @act.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /acts/1
  # DELETE /acts/1.json
  def destroy
    @act = Act.find(params[:id])

    @inshows = ShowItem.where({ act: @act })

    logger.debug("Act delete requested with inshows #{@inshows.count}")

    if @inshows.count > 0
      flash[:alert] = "You can't delete that act because it's part of a show. Remove the act from the show first."
    else
      flash[:notice] = "Act was deleted."
      @act.destroy
      StatsD.increment("troupeit.acts.destroy")
    end

    respond_to do |format|
      format.html {
        if request.referer and request.referer.match(/\/adminindex$/)
          redirect_to action: :adminindex
        else
          redirect_to "/"
        end
      }

      format.json { head :no_content }
    end
  end

  def search
    searchterm = Regexp.escape(params[:search])

    # I guess we are always going to sort by updated at,
    # reversed. Everything else is pretty meaningless.
    sortopt={ updated_at: -1 }

    # determine valid user ID list.
    # for all of the companies that YOU are in, get all of the members.
    @membercomp = CompanyMembership.where(user_id: current_user.id)
    @cohorts = CompanyMembership.in(company_id: @membercomp.map(&:company_id))

    case params[:order].to_i
    when 1
      # by tags -- ok
      @searchresults = Act.in(user_id: @cohorts.map(:user_id)).find(Act.tagged_like(params[:search]))
    else
      # if term we search, not, we do not.
      if searchterm != ""
        @searchresults = Act.in(user_id: @cohorts.map(:user_id)).any_of({ stage_name: /#{searchterm}/i }, { title: /#{searchterm}/i }, { short_description: /#{searchterm}/i }, { names_of_performers: /#{searchterm}/i }).sort(sortopt).limit(50)
      else
        @searchresults = Act.in(user_id: @cohorts.map(:user_id))
      end
    end

    respond_to do |format|
      format.html { render json: @searchresults, include: [ :user ]  }
      format.json { render json: @searchresults, include: [ :user ]  }
    end
  end

  def transfer
    @error = ""
    # get the act
    begin
      @act = Act.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      @error = "Act not found"
      @status = 404
    end

    # are we the owner?
    if @act.user != current_user
      @error = "You are not the owner of that act."
      @status = 403
    end

    # does the destination user exit?
    begin
      @newuser = User.find(params[:newuser])
    rescue Mongoid::Errors::DocumentNotFound
      @error = "No such destination user"
      @status = 400
    end

    if @error == ""
      # reassign act by changing user
      @act.user = @newuser
      @act.save

      # reassign files
      @act.act_asset.each { |p|
        # we will only transfer files that you own.
        if p.passet.user == current_user
          p.passet.user = @newuser
          p.passet.save
        end
      }

      @error = "OK"
      @status = 200
    end

    respond_to do |format|
      format.html {
        flash[:alert] = @error
        redirect_to "/"
      }
      format.json {
        render json: { errors: @error, status: @status }, status: @status
      }
    end
  end

  private

  def attach_passets
    # attach assets to the act
    ActAsset.where(act: @act).destroy

    if params["passetids"].present?
      # we are sent an "ordered" hash with keys representing asset usage order
      # sort this result then iterate.
      n = 1
      params["passetids"].keys.sort.each { |key|
        begin
          p = Passet.find(params["passetids"][key])
          as = ActAsset.new(act: @act, seq: n)
          as.passet = p
          as.save

          logger.info("Act #{@act._id} - #{p.filename}  - appending asset #{key} / #{params["passetids"][key]} now.")
          n=n+1
        rescue Mongoid::Errors::DocumentNotFound
          # silently fail: somehow the passet went away between the
          # time that our form selection took place and now. We're
          # going to log that and move on.
          logger.info("Act #{@act._id} - Asset #{params["passetids"][key]} went away before it could be attached.")
        end
      }
      @act.save
    end
  end


  def validate_return
    @return_to = "/"

    if params[:return_to].present?
      if params[:return_to].match(/^\//)
        @return_to = params[:return_to]
      end
    end
  end

  def length_to_seconds
    if params[:act][:length] == nil
      # let rails complain about this for us.
      logger.debug("length was nil")
      return
    end

    if params[:act][:length].is_a?(Fixnum)
      logger.debug("length was fixnum #{self.length}")
      return 0
    end

    if params[:act][:length].is_a?(Float)
      return 0
    end

    if params[:act][:length].match(/\A(\d+:)*(\d+):(\d+)\z/)
      p = params[:act][:length].split(":")

      if p.length == 3
        if p[0].to_i > 23
          return 0
        end

        if p[1].to_i > 59 or p[2].to_i > 59
          return 0
        end

        t = (p[0].to_i * 60 * 60) + (p[1].to_i * 60) + p[2].to_i
      end

      if p.length == 2
        if p[0].to_i > 59 or p[1].to_i > 59
          return 0
        end

        t = (p[0].to_i * 60) + p[1].to_i
      end

      params[:act][:length] = t
    else
      0
    end
  end

  def act_params
    params.require(:act).permit(:stage_name, :names_of_performers, :contact_phone_number, :length, :short_description, :title, :sound_cue, :prop_placement, :lighting_info, :clean_up, :mc_intro, :run_through, :extra_notes)
  end

  def show_item_params
    params.require(:show_item).permit(:duration, :time, :note, :color)
  end
end
