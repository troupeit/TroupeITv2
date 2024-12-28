class EntryTechinfoController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cache_buster

  before_action :set_entry_techinfo, only: [ :show, :edit, :update, :destroy ]

  # GET /entry_techinfo
  def index
    redirect_to apps_url, alert: "Permission denied."
    logger.info "SECURITY: attempt to load index page for entry_techinfo"
  end

  # GET /entry_techinfo/1
  def show
  end

  # GET /entry_techinfo/new
  def new
    if ! params.has_key?(:app_id)
      redirect_to apps_url, notice: "Cannot find that App ID"
      return
    end
    begin
      @app = App.find(params[:app_id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to apps_url, alert: "Invalid App ID"
    end

    @entry_techinfo = EntryTechinfo.new
  end

  # GET /entry_techinfo/1/edit
  def edit
    if ! params.has_key?(:app_id)
      redirect_to apps_url, notice: "Cannot find that App ID"
      return
    end
    begin
      @app = App.find(params[:app_id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to apps_url, alert: "Invalid App ID"
    end

    @entry_techinfo = @app.entry_techinfo
  end

  # POST /entry_techinfo
  def create
    begin
      @app = App.find(params[:for_app])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to apps_url, alert: "Invalid App ID"
    end

    @entry_techinfo = EntryTechinfo.new(entry_techinfo_params)

    if @entry_techinfo.save
      @app.entry_techinfo = @entry_techinfo
      @app.save
      redirect_to dashboard_app_path(@app), notice: "Technical information saved"
    else
      render action: "new"
    end
  end

  # PATCH/PUT /entry_techinfo/1
  def update
    if ! params.has_key?(:app_id)
      redirect_to apps_url, notice: "Cannot find that App ID"
      return
    end
    begin
      @app = App.find(params[:app_id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to apps_url, alert: "Invalid App ID"
    end

    if @entry_techinfo.update(entry_techinfo_params)
      redirect_to dashboard_app_path(@app), notice: "Technical Information was successfully updated."
    else
      render action: "edit"
    end
  end

  # DELETE /entry_techinfo/1
  def destroy
    @entry_techinfo.destroy
    redirect_to entry_techinfos_url, notice: "Entry techinfo was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_entry_techinfo
      @entry_techinfo = EntryTechinfo.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def entry_techinfo_params
      params.require(:entry_techinfo).permit(:entry_id, :song_title, :song_artist, :act_duration, :act_name, :act_description, :costume_Description, :costume_colors, :props, :other_tech_info, :setup_needs, :setup_time, :breakdown_needs, :breakdown_time, :sound_cue, :microphone_needs, :lighting_needs, :mc_intro, :aerial_needs)
    end
end
