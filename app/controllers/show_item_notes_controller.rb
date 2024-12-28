class ShowItemNotesController < ApplicationController
  before_action :authenticate_user!

  protect_from_forgery

  # POST show_item_note.json
  # Technically, this is a create-or-update call.
  def create
    # initially we assume your request is bad.
    @errtext = "Bad Request - Missing parameters"
    @errstat = 400

    # sanity check
    if params[:show_id].blank? or params[:show_item_id].blank?
      respond_to do |format|
        format.json { render json: { errors: @errtext, status: @errstat }, status: @errstat }
      end
      return
    end

    begin
      @show = Show.find(params[:show_id])
      @show_item = ShowItem.find(params[:show_item_id])
    rescue Mongoid::Errors::DocumentNotFound
      @errtext = "Show or show item not found"
      @errstat = 404

      respond_to do |format|
        format.json { render json: { errors: @errtext, status: @errstat }, status: @errstat }
      end
      return
    end

    # Data OK. Now we do a first or initialize so that we only ever have one message per
    # show item and show item type.
    desired_kind = params[:personal] == true ? ShowItemNote::KIND_PRIVATE : ShowItemNote::KIND_COMPANY

    sn = ShowItemNote.where({ show: @show.id,
                             show_item: @show_item.id,
                             kind: desired_kind,
                             user: current_user.id }).first_or_initialize

    sn.user      = current_user.id

    sn.note      = params[:note].blank? ? "" : params[:note]

    # show_item, kind, and show are a three-way, compound key for this note
    sn.show_item = @show_item.id
    sn.show      = @show.id
    sn.kind      = desired_kind

    if sn.save
      @errtext = "Note added"
      @errstat = 200
    else
      @errtext = "Save failed due to validation or other error."
      @errstat = 400
    end


    respond_to do |format|
      format.json { render json: { errors: @errtext, status: @errstat }, status: @errstat }
    end
  end

  def destroy
  end
end
