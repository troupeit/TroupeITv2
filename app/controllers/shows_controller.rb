class ShowsController < ApplicationController
  protect_from_forgery

  include ApplicationHelper

  before_action :authenticate_user!, except: [ :passets ]
  before_action :build_company_select, only: [ :new, :edit, :update, :create ]
  before_action :analyze_passets, only: [ :download, :passets ]

  # GET /shows
  # GET /shows.json
  def index
    if params[:event_id].present?
      @shows = Show.where(event_id: params[:event_id]).asc(:door_time)
    else
      @shows = Show.all.desc(:door_time)
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json {
        @showarray = []
        @shows.each { |show|
            @showarray << { "title" => show.title,
                            "venue" => show.venue,
                            "room" => show.room,
                            "door_time" => show.door_time,
                            "show_time" => show.show_time,
                            "id" => show._id.to_s }
            }

        render json: { "aaData" => @showarray }
      }
    end
  end

  def live
    @show = Show.find(params[:id])
    @event = @show.event
    render layout: "liveview"
  end

  # GET /shows/1/perfindex...
  # this is list of all performers in this show, for the setlist.
  def perfindex
    @show = Show.find(params[:id])
    @show_items = ShowItem.where(show_id: params[:id]).asc(:seq)
    @si_act = Hash.new

    # prefetch the acts in this show
    @show_items.each { |si|
      act = nil
      begin
        if si.kind == ShowItem::KIND_ASSET
          # this is an asset.
          if si.act_id != nil
            act = Act.find(si.act_id)
          end
        end
        @si_act[si.act_id] = act
      rescue
        # this act is not part of the show and therefore, we do not add it.
        @si_act[si.act_id] = nil
      end
    }
  end

  def refresh_act_times
    # walk through a show and for each act in the show reload the time from the Act
    # itself
    @show = Show.find(params[:id])
    @show_items = ShowItem.where(show_id: params[:id]).asc(:seq)
    logger.debug "updating act times for show #{@show.id}"

    @show_items.each { |si|
      if si.act_id != nil
        begin
           act = Act.find(si.act_id)
           logger.debug "#{act.id} fix time was: #{si.duration} now: #{act.length}"
           si.duration = act.length
           si.save
        rescue Mongoid::Errors::DocumentNotFound
          # Not an act
        end
      end
    }

    redirect_to edit_show_path(@show), notice: "Times for this show have been refreshed from Act data"
  end

  # GET /shows/1
  # GET /shows/1.json
  def show
    @show = Show.find(params[:id])
    @show_items = ShowItem.where(show_id: params[:id]).order_by(seq: "asc")

    # did they specify an order?
    if params[:order].present?
      @order = params[:order].split(",")
    else
      @order = [ 0, 1, 2, 3, 4, 5, 6, 7 ]
    end

    if params[:checked].present?
      @checked = params[:checked].split(",")
    else
      @checked = [ 1, 1, 1, 1, 1, 1, 0, 0 ]
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @show, include: { show_items: { include: { act: { include: :user } } } } }

      format.csv {
        # construct the CSV array based on the show data
        @csvarry = make_csv
        row=0
        out = CSV.generate do |csv|
          @csvarry.each do |h|
            if row == 0
              csv << h.keys
            end
            csv << h.values
            row=row+1
          end
        end

        send_data out, type: "text/csv; charset=iso-8859-1; header=present", disposition: "attachment;data=show.csv"
      }

      format.xls {
        @csvarry = make_csv
      }


      format.pdf {
        pdf = CueListReportPdf.new(current_user, @show, @order, @checked)

        send_data pdf.render,
                  filename: FileTools.sanitize_csv_filename("#{@show.event.title} - #{@show.title}"),
                  type: "application/pdf",
                  disposition: "inline"
      }
    end
  end




  # GET /shows/new
  # GET /shows/new.json
  def new
    @event = Event.new
    @show = Show.new
    @show.event = @event

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @show }
    end
  end

  # GET /shows/1/edit
  def edit
    begin
      @show = Show.find(params[:id])
      @show_items = ShowItem.where(show_id: params[:id])
    rescue
      flash[:alert] = "Problem loading show -- Show or show items do not exist."
      redirect_to "/shows"
      return
    end

    # we keep one of these in reserve for the modal if it's needed.
    @show_item = ShowItem.new
  end

  # GET /shows/1/items
  def items
    @show_items = ShowItem.where(show_id: params[:id])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @show_items }
    end
  end

  def analyze_passets
    # return all passet IDs for a given show ID.
    # used by the Go service to create a download

    # we will also return the metadata records that need to be added to
    # the zip for applescript/qlab importing

    @show_items = ShowItem.where(show_id: params[:id]).asc(:seq)
    @show = Show.find(params[:id])
    @filelist = Array.new
    @nomedia = Array.new

    @safe_title = FileTools.sanitize_filename(@show.title)
    @stat_acts = 0
    @stat_music = 0
    @stat_images = 0

    @zipstat = 0

    seq = 0

    @mediaused = []
    @metaf = []
    @dupemedia = []

    @show_items.each { |s|
      if s.kind != ShowItem::KIND_NOTE
        begin
          a = Act.find(s.act_id)
        rescue Mongoid::Errors::DocumentNotFound
          # there is a record associated with this show which doesn't exist anymore
          logger.debug("warning: act id #{s.act_id} doesn't exist but show #{@show.id} still references it.")
          # we silently skip the item if we can't locate the act or if the
          # ID in question is invalid (i.e. 0 or 1)
          next
        rescue Mongoid::Errors::InvalidFind
          # Deleted Act.
          next
        end

        @noimage = true
        @nomusic = true

        if a.present?
          @stat_acts += 1
          if a.act_asset.present?
            begin
              a.act_asset.each { |aa|
                begin
                  p = aa.passet
                  assetinfo = { act_id: s.act_id,
                                show_item_id: s.id.to_s,
                                act_owner: s.act.stage_name,
                                act_user: s.act.user,
                                created_at: p.created_at,
                                uuid: p.uuid,
                                kind: p.kind,
                                size: p.asset_bytesize,
                                song_artist: p.song_artist,
                                song_title: p.song_title,
                                song_length: p.song_length,
                                img_size_x: p.img_size_x,
                                img_size_y: p.img_size_y,
                                filename: FileTools.sanitize_filename(p.filename)
                              }
                  seq += 1
                  if p.asset_bytesize
                    @zipstat = @zipstat + p.asset_bytesize
                  end

                  typetag = "Unknown"
                  if p.is_audio?
                    @stat_music += 1
                    @nomusic = false
                    typetag = "Audio"
                  end

                  if p.is_image?
                    @stat_images += 1
                    @noimage = false
                    typetag = "Video"
                  end

                  @metaf << "#{typetag}\t#{s.color}\t#{s.title}\t#{s.act.sound_cue.gsub(/(\r|\n)/, " ")}\t#{sprintf("%02d", seq)}_#{assetinfo[:filename]}"

                  @filelist << assetinfo
                  if @mediaused.find_index(p.uuid).nil?
                    @mediaused << p.uuid
                  else
                    @dupemedia <<  {
                      uuid: p.uuid,
                      act_id: s.act_id,
                      show_item_id: s.id.to_s,
                      act_owner: s.act.stage_name,
                      act_user: s.act.user,
                      filename: FileTools.sanitize_filename(p.filename)
                    }
                  end
                rescue Mongoid::Errors::DocumentNotFound
                  logger.info("Passet music - #{aa} referenced in act #{s.act_id} but not in Passet table?")
                end
              }
            end

          else
            @nomedia <<  {
              act_id: s.act_id,
              show_item_id: s.id.to_s,
              act_owner: s.act.stage_name,
              act_user: s.act.user
            }

            # if no media, we just add the title and mark it in red, but keep the sound cue notes if any.
            @metaf << "Memo\tred_bg\t#{s.title}\t#{s.act.sound_cue.gsub(/(\r|\n)/, " ")}\t"
          end
        end
      else
        @metaf << "Memo\t#{s.color}\t#{s.title}\t"
      end
    }
  end

  def passets
    # very detailed response including show items data and files
    # used by troupeIT player and s3zipper
    respond_to do |format|
      format.json { render json: { filelist: @filelist,
                                   show: @show,
                                   meta: @metaf,
                                   nomedia: @nomedia,
                                   dupemedia: @dupemedia,
                                   stat_acts: @stat_acts,
                                   stat_images: @stat_images,
                                   stat_music: @stat_music
                                 },
                           include: { show_items: { include: { act: { include: :user } } } }
                   }
    end
  end

  def download
    # just show the view.
  end

  def download_redir
    begin
      @show = Show.find(params[:id])
    rescue
      flash[:alert] = "Problem loading show -- Show or show items do not exist."
      redirect_to "/shows"
      return
    end

    @show.last_download_at = Time.now
    @show.last_download_by = current_user
    @show.save

    redirect_to "https://troupeit.com/gf/?show_id=" + @show._id.to_s
  end

  # AJAX endpoint
  def show_items
    @show_items = ShowItem.where(show_id: params[:id]).asc(:seq)
    @show = Show.find(params[:id])

    itemtime = @show.door_time
    respond_to do |format|
      format.html { render action: "index" }
      format.json {
        # this format drives the show display index
        @si = []
        @show_items.each { |s|
          # menus are built based on a number of items and we must provide them over Ajax to datatables
          markact = ""
          editact = ""
          editdur = ""
          removeme = ""
          moveme = ""
          highlighted = false

          if params[:m].nil?
            # this one is used by the editor...
            moveme = "<button class=\"btn btn-dark btn-mini noprint moveup\" id=\"#{s._id}\"><i class=\"glyphicon glyphicon-arrow-up white\"></i></button>&nbsp;<button class=\"btn btn-dark btn-mini noprint movedown\" id=\"#{s._id}\"><i class=\"glyphicon glyphicon-arrow-down white\"></i></button>&nbsp;"
            moveme = moveme + "<button class=\"btn btn-dark btn-mini noprint exact\" id=\"#{s._id}\"><i class=\"glyphicon glyphicon-screenshot white\"></i></button><BR>"
            removeme = "<button class=\"btn btn-danger btn-mini noprint sidestroy\" id=\"#{s._id}\"><i class=\"glyphicon glyphicon-trash white\"></i></button>&nbsp;"
            editact = "<button class=\"btn btn-success btn-mini noprint editact\" id=\"#{s.act_id}\"><i class=\"glyphicon glyphicon-pencil white\"></i></button>&nbsp;"
            editdur = "<button class=\"btn btn-info btn-mini noprint editduration\" id=\"#{s._id}\"><i class=\"glyphicon glyphicon-time white\"></i></button>&nbsp;"
          else
            # this one is used by the viewer.
            if s.id.to_s == @show.highlighted_row.to_s
              highlighted = true
            else
              highlighted = false
            end
          end

          # seq, time, act data, sound, light+stage, notes
          if s.kind != ShowItem::KIND_NOTE
            # this is an asset.
            if s.act_id != nil
              begin
                act = Act.find(s.act_id)
              rescue Mongoid::Errors::DocumentNotFound
                act = nil
              end
            end

            if act == nil
              # something is seriously wrong.
              actinfo = "<B><font color=\"#ff0000\">Cannot find Act ID #{s.act_id}, record #{s._id}</font></B>"
              if params[:m].nil?
                @si << [ s.seq, s.time, "--", 0, "--", "--", actinfo, "" ]
              else
                @si << {
                 "seq" => s.seq,
                 "cue" => actinfo,
                 "cue_description" => actinfo,
                 "mc_intro" => "",
                 "sound" => "",
                 "lights" => "",
                 "stage" => "",
                 "clean_up" => "",
                 "performer_notes" => "",
                 "highlighted" => highlighted
                }
              end
            else
              actinfo = "<B>#{act.stage_name}</B><BR>#{act.short_description}"

              sound = ""
              if act.sound_cue == ""
                sound = sound + "<B>CUE:</B> Not specified"
              else
                sound = sound + "<B>CUE:</B> #{act.sound_cue}"
              end

              # build the stage instructions from all the fields
              stage = ""

              if act.mc_intro != ""
                stage += "<B>MC INTRO:</B> #{act.mc_intro}<BR>"
              end

              if act.lighting_info != ""
                stage += "<B>LIGHTS:</B> #{act.lighting_info}<BR>"
              end

              if act.prop_placement != ""
                stage += "<B>STAGE:</B> #{act.prop_placement}<BR>"
              end

              if act.clean_up != ""
                stage += "<B>CLEANUP:</B> #{act.clean_up}<BR>"
              end

              if params[:m].nil?
                @si << { "DT_RowId" => s._id.to_s,
                  "0" => s.seq,
                  "1" => "#{itemtime.strftime("%l:%M %P")}<BR>+#{TimeTools.sec_to_time(s.duration.to_i)}",
                  "2" => actinfo,
                  "3" => sound,
                  "4" => stage,
                  "5" => act.extra_notes,
                  "6" => moveme + removeme + editact + editdur + markact
                }
              else
                @si << { "DT_RowId" => s._id.to_s,
                  "seq" => s.seq,
                  "cue" => "<div id=\"top\"><h4>#{act.stage_name}</h4></div><div id=\"bot\">#{itemtime.strftime("%l:%M %P")} | +#{TimeTools.sec_to_time(s.duration.to_i)}</div>",
                  "cue_description" => act.short_description,
                  "mc_intro" => act.mc_intro,
                  "sound" => sound,
                  "lights" => act.lighting_info,
                  "stage" => act.prop_placement,
                  "clean_up" => act.clean_up,
                  "performer_notes" => act.extra_notes,
                  "highlighted" => highlighted
                }
              end

              if s.duration != nil
                  itemtime = itemtime + s.duration.to_i
              end
            end

          else
            if params[:m].nil?
              # note
              @si << { "DT_RowId" => s._id.to_s,
                 "0" => s.seq,
                 "1" => "#{itemtime.strftime("%l:%M %P")}<BR>+#{TimeTools.sec_to_time(s.duration.to_i)}",
                 "2" => "--",
                 "3" => "--",
                 "4" => "--",
                 "5" => "<B>" + s.note + "</B>",
                 "6" => moveme + removeme + editdur + markact
             }
            else
              @si << { "DT_RowId" => s._id.to_s,
                 "seq" => s.seq,
                 "cue" => "<h4>#{s.note}</h4><div id=\"bot\">#{itemtime.strftime("%l:%M %P")} | +#{TimeTools.sec_to_time(s.duration.to_i)}</div>",
                 "cue_description" => "",
                 "mc_intro" => "",
                 "sound" => "",
                 "lights" => "",
                 "stage" => "",
                 "clean_up" => "",
                 "performer_notes" => "",
                 "highlighted" => highlighted
              }
            end

            if s.duration != nil
                itemtime = itemtime + s.duration.to_i
            end
          end
        }
        render json: { "iTotalRecords" => @si.length, "aaData" => @si, "highlighted" => @show.highlighted_row }
      }
    end
  end

  # POST /shows
  # POST /shows.json
  def create
    @show = Show.new(show_params)

    if not params[:show][:event_id].present?
      render json: { error: "Event ID is Required.", status: 422 }, status: :bad_request
      return
    else
      begin
        # SECURITY: TODO: Verify owner / company access
        @event = Event.find(params[:show][:event_id])
        @show.event_id = @event._id
      rescue Mongoid::Errors::DocumentNotFound
        render json: { error: "Supplied Event ID not Found", status: 422 }, status: :bad_request
        return
      end
    end

    respond_to do |format|
    begin
      if @show.save
        StatsD.increment("troupeit.show.create")
        @event.shows << @show
        @event.save

        format.html { redirect_to shows_url, notice: "Show was successfully created." }
        format.json { render json: @show, status: :created, location: @show }
      else
        # whooops.
        @event.destroy

        format.html { render action: "new" }
        format.json { render json: @show.errors, status: :unprocessable_entity }
      end
    rescue Mongoid::Errors::InvalidTime
        flash[:alert] = "Invalid Date Format."
    end
    end
  end

  # PUT /shows/1
  # PUT /shows/1.json
  def update
    @show = Show.find(params[:id])

    # when we are doing a MARK operation, we do not update the company_id.
    # confirm it exists before trying to update it.
    if params[:company_id].present?
      begin
        @tr = Company.find(params[:company_id])
        @show.company_id = @tr.id
      rescue Mongoid::Errors::DocumentNotFound
        # If we can't find it, we leave it blank.
        @show.company_id = nil
      end
    end

    @show_items = ShowItem.where(show_id: params[:id])
    @show_item = ShowItem.new

    prev_door_time = @show.door_time
    prev_show_time = @show.show_time

    respond_to do |format|
      if @show.update_attributes(show_params)
        StatsD.increment("troupeit.show.update")

        # if the times changed, clear the notifications sent field
        if @show.door_time != prev_door_time or @show.show_time != prev_show_time
          PublicActivity.enabled = false
          @show.notifications_sent = false
          @show.save
          PublicActivity.enabled = true
        end

        format.html { redirect_to "/shows/#{@show.id}/edit", notice: "Show details were successfully updated." }
        format.json { head :no_content }
      else
        format.html { redirect_to "/shows/#{@show.id}/edit" }
        format.json { render json: @show.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /shows/1
  # DELETE /shows/1.json
  def destroy
    @show = Show.find(params[:id])
    @show.destroy
    StatsD.increment("troupeit.show.destroy")

    respond_to do |format|
      format.html { redirect_to shows_url }
      format.json { head :no_content }
    end
  end

  private

  def make_csv
    @csvarry = Array.new
    @cuetime = @show.door_time

    @show_items.each { |si|
      @csvout = Hash.new
      @csvout["seq"] = si.seq
      @csvout["start_time"] = @cuetime

      if si.kind == ShowItem::KIND_ASSET and not si.act.blank?
        # act
        if not si.act.title.blank?
          title = si.act.stage_name + ": " +  si.act.title
        else
          title = si.act.stage_name
        end
        owner = ""
        if si.act.present?
          owner = si.act.user.name
        end

        @csvout["performer"] = owner
        @csvout["cue_title"] = title
        @csvout["cue_description"] = si.act.short_description
        @csvout["sound_cue"] = si.act.sound_cue
        @csvout["lights"] = si.act.lighting_info
        @csvout["stage"] = si.act.prop_placement
        @csvout["cleanup"] = si.act.clean_up
        @csvout["performer_notes"] = si.act.extra_notes
      else
        if si.kind == ShowItem::KIND_ASSET
          title = "*** Deleted Act ***"
        else
          title = si.note
        end
        @csvout["cue_title"] = title
        @csvout["cue_description"] = ""
        @csvout["sound"] = ""
        @csvout["lights"] = ""
        @csvout["stage"] = ""
        @csvout["cleanup"] = ""
        @csvout["performer_notes"] = ""
      end

      if si.duration.present?
        @csvout["duration"] = si.duration
        @cuetime = @cuetime + si.duration
      else
        @csvout["duration"] = 0
      end

      @csvarry << @csvout
    }

    @csvarry
  end

  # TODO: move to "passet helper" - this duplicaes passets_controller.rb
  def embed_for(asset)
    if asset.is_audio?
      if is_mobile_device? or is_tablet_device?
        embed_html = "<a href=\"/sf/#{asset.uuid}\">[ play ]</a>"
      else
        embed_html = "
        <audio src=\"/sf/" + asset.uuid + "\" controls=\"true\" preload=\"none\" width=150 height=20>
           <object width=\"100\" height=\"30\" type=\"application/x-shockwave-flash\" data=\"/mejs/flashmediaelement.swf\">
           <param name=\"movie\" value=\"/mejs/flashmediaelement.swf\" />
           <param name=\"flashvars\" value=\"controls=true&file=/sf/" + asset.uuid + "\" />
           </object>
        </audio><BR>"
      end
    end

    if asset.is_image?
      embed_html = "<a id=\"single_image\" href=\"/sf/" + asset.uuid + ".jpg\" rel=\"\">
       <IMG SRC=\"/s/" + asset.thumb_path(100, 100) + "\" WIDTH=100 HEIGHT=100></a>"
    end

    embed_html
  end

  def build_company_select
    @companysel = Array.new

    current_user.company_memberships.each { |tm|
      if tm.company
        @companysel << tm.company
      end
    }
  end

  def show_params
    params.require(:show).permit(:title, :show_time, :door_time, :venue, :event_id, :title, :goog_place_id, :room, :emergency_msg, :highlighted_row, :highlighted_at, :showitem_seq)
  end
end
