require "fileutils"
require "securerandom"

class PassetsController <  ApplicationController
  protect_from_forgery except: [ :create, :webhook ]

  before_action :authenticate_user!, except: :webhook
  before_action :verify_admin, only: [ :update, :edit, :adminindex ]

  # this tends to explode on file upload, turning it off.
  skip_before_action :verify_authenticity_token,  only: [ :new ]

  def index
    if params[:company_id].present?
      # find assets for the company.
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
      @assets = Passet.in(user_id: @cohorts.map(:user_id))
    else
      @assets = current_user.passets.all.desc(:created_at)
    end

    # TODO: portions of this code duplicate adminindex.
    # TODO: We are attempting for privilege separation here but i hate repeating code

    respond_to do | format|
      format.html { render :index }
      format.json {
        @filesarray = []
        @assets.each { |a|
          begin
            @u = User.find(a.created_by)
          rescue
            @u = nil
          end

          objectstring = embed_for(a)
          # here we pass some fields twice to ensure they can be used for sorting
          # The current version of griddle cannot search on objects, only strings
          @filesarray << { id: a.id.to_s,
                           user_name: @u.username,
                           name: @u.name,
                           user: @u,
                           asset: a,
                           asset_filename: a.filename,
                           asset_details: a,
                           created: a.created_at
          }
        }
        render json: { "files" => @filesarray }
      }
    end
  end

  def download
    begin
      StatsD.increment("troupeit.passet.downloads")
      @passet = Passet.find(params[:id])
      redirect_to "/sf/#{@passet.uuid}/1"
    rescue Mongoid::Errors::DocumentNotFound
      flash[:alert] = "Error. File not found."
      redirect_to "/"
    end
  end

  def adminindex
    if current_user.try(:admin?)
      @assets = Passet.all.desc(:created_at)
      @adminindex = true
      respond_to do | format|
        format.html { render :index }
        format.json {
          @filesarray = []
          @assets.each { |a|
             begin
               @u = User.find(a.created_by)
               userstring = "<a href=\"/users/#{a.created_by}\">#{@u.name}</a><BR><a href=\"mailto:#{@u.email}\">#{@u.email}</a>"
             rescue
               userstring = "<font color=\"#ff0000\">Deleted User</font>"
             end
             objectstring = embed_for(a)

             @filesarray << [ userstring, objectstring, a.to_html, a.id.to_s ]
          }
          render json: { "aaData" => @filesarray }
       }
      end
    else
      flash[:alert] = "You must be an administrator to use that function."
      redirect_to "/"
    end
  end

  def new
    # HACK: find out if user is a hubba user and if so give them some additional help.
    # future - let companies do this on a per company basis.

    @is_hubba_user = false

    current_user.companies.each { |c|
      if c.id.to_s == "54c986c868756257cc000000"
        @is_hubba_user = true
      end
    }
  end

  def edit
    @passet = Passet.find(params[:id])
    @adminindex = true
  end

  def enqueue
    render json: { errors: "Endpoint no longer permitted", status: 400 }, status: 400
  end

  def update
    @passet = Passet.find(params[:id])

    if current_user.try(:admin?) == false and @passet.user != current_user
      respond_to do |format|
        format.html {
          flash[:notice] = "You are not the owner of that asset."
          # only admins can ever do this, so go back there.
          redirect_to "/"
          return
        }

        format.json {
          render json: { errors: "Forbidden", status: 403, passet: @passet }, status: 403
          return
        }
      end
    end

    if current_user.try(:admin?)
      @passet.update_attributes(admin_passet_params)
    else
      @passet.update_attributes(passet_params)
    end

    @passet.save!
    StatsD.increment("troupeit.passet.updates")

    respond_to do |format|
      format.html {
        flash[:notice] = "Updated information for #{@passet.filename}"
        # only admins can ever do this, so go back there.
        redirect_to action: :adminindex
      }

      format.json {
        render json: { errors: "Updated", status: 200, passet: @passet }, status: 200
      }
    end
  end

  def webhook
    # this webhook is called by the S3 processor.
    StatsD.increment("troupeit.passet.updates")

    if params[:passet].blank? or params[:oldpasset].blank?
      respond_to do |format|
        format.json {
          render json: { error: "Bad Request", status: 400 }, status: :bad_request
        }
      end
      return
    end

    begin
      if params[:oldpasset].has_key?("uuid")
        @passet = Passet.where({ uuid: params[:oldpasset]["uuid"] }).first
      else
        @passet = Passet.find(params[:oldpasset]["_id"]["$oid"])
      end
    rescue Mongoid::Errors::DocumentNotFound
      @passet = nil
    end

    if @passet.nil?
      respond_to do |format|
        format.json {
          render json: { error: "Asset Not Found", status: 404 }, status: :not_found
        }
      end
      return
    end

    @passet.update_attributes(webhook_params)
    @passet.save

    respond_to do |format|
      format.json {
        render json: { errors: "Updated", status: 200, passet: @passet }, status: 200
      }
    end
  end

  def destroy
    # todo - ensure ownership here.
    p = Passet.find(params[:id])

    if p != nil
      logger.debug("Delete requested for Asset #{p.uuid}, #{request.referer}")

      client = Aws::SQS::Client.new(access_key_id: Rails.application.credentials.aws_access_key,
                                     secret_access_key: Rails.application.credentials.aws_secret_key,
                                     region: Rails.application.credentials.aws_sqs_region)

      client.send_message({ queue_url: Rails.application.credentials.aws_sqs_baseurl + "delete_processing",
                            message_body: p.to_json })
      p.destroy

      StatsD.increment("troupeit.passet.destroy")
    end

    if request.referer.match(/\/adminindex$/)
      redirect_to action: :adminindex
    else
      redirect_to action: :index
    end
  end

  def create
    # this is called by BeforeUpload to generate an S3 policy
    @uuid = SecureRandom.uuid

    if params[:filename].blank?
      render nothing: true, status: 400
      return
    end

    # construct a filename
    @filename = @uuid + File.extname(params[:filename])

    @p = Passet.new(uuid: @uuid,
                    filename: params[:filename],
                    asset_bytesize: params[:size],
                    kind: params[:kind],
                    created_by: current_user.id,
                    processed: 0
                   )

    # this hasn't happened yet, but let's track it anyway.
    StatsD.increment("troupeit.passet.create")
    StatsD.increment("troupeit.passet.uploaded_bytes", @p.asset_bytesize)

    if @p.save == false
      respond_to do |format|
        format.json { render json: { errors: "missing required fields", status: 400 }, status: 400 }
      end

      return
    end

    current_user.passets << @p

    respond_to do |format|
      format.json {
        render json: { formUrl: "https://troupeit-uploads.s3.amazonaws.com:443/",
                       formData: {
                         filename: @filename,
                         AWSAccessKeyId: Rails.application.credentials.aws_access_key,
                         policy: s3_gen_policy(@filename),
                         signature: s3_signature(@filename),
                         key: "uploads/#{@filename}",
                         status: :created
                       },
                       passet: @p
                     }
      }
    end
  end

  def search
    StatsD.increment("troupeit.passet.searches")

    case params[:searchopt].to_i
    when 0
      @presort = current_user.passets.all
    when 1
      @membercomp = CompanyMembership.where(user_id: current_user.id)
      @cohorts = CompanyMembership.in(company_id: @membercomp.map(&:company_id))
      @presort = Passet.in(user_id: @cohorts.map(:user_id))
    end

    # terms
    if params[:term].present?
      @presort = @presort.any_of({ filename: /#{params[:term]}/i },
                                 { song_artist: /#{params[:term]}/i },
                                 { song_title: /#{params[:term]}/i })

    end


    if params[:mimetype].present? and params[:mimetype] != "*"
      @presort = @presort.where({ kind: /^#{params[:mimetype]}/ })
    end

    @presort = @presort.limit(25)

    case params[:sortopt].to_i
    when 0
      @assets = @presort.order_by(created_at: "desc")
    when 1
      @assets = @presort.order_by(filename: "asc")
    end

    render json: @assets.to_json(include: :user)
  end

  private

  def s3_signature(filename)
    Base64.encode64(
      OpenSSL::HMAC.digest(
      OpenSSL::Digest::Digest.new("sha1"),
        Rails.application.credentials.aws_secret_key, s3_gen_policy(filename)
      )
    ).gsub("\n", "")
  end

  def s3_gen_policy(filename)
    conditions = [
      [ "starts-with", "$utf8", "" ],
      [ "eq", "$key", "uploads/" + filename ],
      [ "eq", "$filename", filename ],
      [ "starts-with", "$content-type", "" ],  # potentially insecure, might want to limit.
      [ "starts-with", "$name", "" ],
      { "bucket" => "troupeit-uploads" },
      { "acl" => "public-read" }
    ]

    policy = {
      # Valid for 1 minute, as we fetch policy on-demand
      "expiration" => (Time.now.utc + 60).iso8601,
      "conditions" => conditions
    }

    Base64.encode64(JSON.dump(policy)).gsub("\n", "")
  end

  # TODO: move to "passet helper"
  def embed_for(asset)
    if asset.is_audio?
     embed_html = "
      <audio src=\"/sf/" + asset.uuid + "\" controls=\"true\" preload=\"none\">
         <object width=\"100\" height=\"30\" type=\"application/x-shockwave-flash\" data=\"/mejs/flashmediaelement.swf\">
         <param name=\"movie\" value=\"/mejs/flashmediaelement.swf\" />
         <param name=\"flashvars\" value=\"controls=true&file=/sf/" + asset.uuid + "\" />
         </object>
      </audio>
      "
    end

    if asset.is_image?
      embed_html = "<a id=\"single_image\" href=\"/sf/" + asset.uuid + ".jpg\" rel=\"\">
       <IMG SRC=\"/s/" + asset.thumb_path(100, 100) + "\" WIDTH=100 HEIGHT=100></a>"
    end

    embed_html
  end

  def determine_mime_type(filename)
    parts = filename.split(".")

    # hackery for keynote, which internally is a zipfile
    if parts[2] == "key"
       return "application/vnd.apple.keynote"
    end

    if parts[1].nil?
       return "application/octet-stream"
    end

    IO.popen([ "file", "--brief", "--mime-type", filename ], in: :close, err: :close).read.chomp
  end

  def verify_admin
    if current_user.try(:admin?) == false
      flash[:alert] = "You must be an administrator to use that function."
      redirect_to "/passets/"
    end
  end

  private

  def webhook_params
    params.require(:passet).permit(:song_length, :img_size_x, :img_size_y, :duration, :song_artist, :song_title, :song_bitrate, :kind, :processed)
  end

  def passet_params
    # you can't change anything but the notes -- fix for admin?
    params.require(:passet).permit(:notes, :status)
  end

  def admin_passet_params
    # you can't change anything but the notes -- fix for admin?
    params.require(:passet).permit(:notes,
                                   :status,
                                   :uuid,
                                   :filename,
                                   :kind,
                                   :notes,
                                   :song_artist,
                                   :song_title,
                                   :song_length,
                                   :asset_bytesize)
  end
end
