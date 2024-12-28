class ShowItemsController < ApplicationController
  before_action :authenticate_user!

  # GET /show_items
  # GET /show_items.json
  def index
    respond_to do |format|
      format.html { render text: "Forbidden", status: 403 }
      format.json { render json: { error: "not allowed" }, status: 403 }
    end
  end

  # GET /show_items/1
  # GET /show_items/1.json
  def show
    @show_item = ShowItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @show_item }
    end
  end

  # GET /show_items/new
  # GET /show_items/new.json
  def new
    @show_item = ShowItem.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @show_item }
    end
  end

  # GET /show_items/1/edit
  def edit
    @show_item = ShowItem.find(params[:id])
  end

  def update_seq
    # this handler takes care of row reordering from datatables.
    if params[:fromPosition] == params[:toPosition]
      render text: "Not Modified", status: 304
      return
    end

    if is_numeric?(params[:fromPosition]) == false or is_numeric?(params[:toPosition]) == false or params[:id] == ""
      render text: "Invalid Request", status: 400
      return
    end

    @item = ShowItem.find(params[:id])
    if @item == nil
      headers["Status"] = 404
      render text: "Show Item Not Found", status: 404
      return
    end

    from_id = nil
    to_id = nil

    @items = ShowItem.where(show_id: @item.show_id)
    @items.each { |i|
      if i.seq.to_i == params[:toPosition].to_i
          to_id = i
      end
      if i.seq.to_i == params[:fromPosition].to_i
          from_id = i
      end
    }

    if from_id != nil and to_id != nil
      to_id.seq = params[:fromPosition].to_i
      to_id.save!
      from_id.seq = params[:toPosition].to_i
      from_id.save!
    else
      render text: "Not Found - f:#{from_id} t:#{to_id} sid:#{@item.show_id} pf:#{params[:toPosition]} pt: #{params[:fromPosition]}", status: 404
      return
    end

    render text: "Ok", status: 200
  end

  # POST /show_items/id/moveexact.json
  def moveexact
    # move an item to an exact location in the showitems list for a particular show
    begin
      @show_items = ShowItem.where(show_id: params[:show_id]).asc(:seq)
    rescue Mongoid::Errors::DocumentNotFound
      render json: { error: "cannot find show" }, status: 404
      return
    end

    if @show_items.count == 0
      render json: { error: "cannot find show" }, status: 404
      return
    end

    if not params[:new_location].present?
      render json: { error: "missing new location" }, status: 422
      return
    end

    if params[:new_location].to_i < 1 or params[:new_location].to_i > @show_items.count
      render json: { error: "bad new location #{params[:new_location].to_i} for show item in show, max is #{@show_items.count}." }, status: 422
      return
    end

    begin
      @moving_item = ShowItem.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      render json: { error: "cannot find existing item" }, status: 404
      return
    end

    newpos = params[:new_location].to_i
    oldpos = @moving_item.seq

    if newpos > oldpos
       @show_items.each { |si|
         if si.seq > oldpos and si.seq < newpos+1
           si.seq = si.seq-1
           si.save
         end
       }
    else
       @show_items.each { |si|
         if si.seq < oldpos and si.seq >= newpos
           si.seq = si.seq+1
           si.save
         end
       }
    end

    @moving_item.seq = newpos
    @moving_item.save

    @moving_item.create_activity action: "item_moved", owner: current_user

    respond_to do |format|
       format.json { render json: { error: "Moved." }, status: 200 }
    end
  end

  # POST /show_items/id/move.json
  def move
    # move a show item up or down in the setlist
    @row_id = params[:row_id]
    @direction = params[:direction]
    @show_items = ShowItem.where(show_id: params[:show_id]).asc(:seq)

    if (@row_id.to_i == @show_items[0].seq and @direction == "up") or
       (@row_id.to_i == @show_items[@show_items.count - 1].seq and @direction == "down") or
        not params[:direction].present? or
        not params[:row_id].present?
      # criteria not met
      render json: {}, status: 400
      return
    end

    if @show_items.length == 0
      render json: {}, status: 404
      return
    end

    last_item = nil
    the_item = nil

    if @direction == "up"
      @show_items.each { |si|
        if si.seq.to_i == @row_id.to_i
          # swap the items
          the_item = si
          stash = the_item.seq
          the_item.seq = last_item.seq
          last_item.seq = stash
          the_item.save!
          last_item.save!
          the_item.create_activity action: "item_moved", owner: current_user
        end
        last_item = si
      }
    end

    if @direction == "down"
      @show_items.reverse.each { |si|
        if si.seq.to_i == @row_id.to_i
          # swap
          the_item = si
          stash = the_item.seq
          the_item.seq = last_item.seq
          last_item.seq = stash
          the_item.save!
          last_item.save!
          the_item.create_activity action: "item_moved", owner: current_user
        end
        last_item = si
      }
    end

    if @direction == "duplicate"
      # a duplicate is just like a move, except we write the item again.
      incrementing = false
      @show_items.each { |si|
        if incrementing == true
          si.seq = si.seq + 1
          si.save
        end

        if si.seq.to_i == @row_id.to_i
          the_item = si
          dupitem = si.dup

          the_item.create_activity action: "item_duplicated", owner: current_user

          dupitem.seq = the_item.seq+1
          dupitem.save

          incrementing = true
        end

        last_item = si
      }
    end

    if the_item == nil
      render json: {}, status: 404
    else
      render json: @the_item, status: 200
    end
  end

  # POST /show_items
  # POST /show_items.json
  def create
    @show_item = ShowItem.new(show_item_params)

    # CRITICAL: atomically update the sequence number
    @show = Show.where(id: params[:show_item][:show_id]).find_one_and_update({ "$inc" => { showitem_seq: 1 } })

    if @show.nil?
      respond_to do |format|
        format.html { render action: "new" }
        format.json { render json: @show_item.errors, status: :not_found }
      end
      return
    end

    @show_item.seq = @show.showitem_seq

    # Show item is now safe, as it's new...
    if @show_item.act_id != nil
      if @show_item.kind == ShowItem::KIND_ASSET
        # if an act_id is supplied, we'll pull the duration from the user's input.
        act = Act.find(@show_item.act_id)
        @show_item.duration = act.length
      end
    end

    # TODO: breakage. if this update fails we now have an incremented SEQ # and a gap in our numbering.
    # this will break moveUp/MoveDown, but at least our sequence is safe
    respond_to do |format|
      if @show_item.save
        format.html { redirect_to @show_item, notice: "Show item was successfully created." }
        format.json { render json: @show_item, status: :created, location: @show_item }
      else
        format.html { render action: "new" }
        format.json { render json: @show_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /show_items/1
  # PUT /show_items/1.json
  def update
    @show_item = ShowItem.find(params[:id])

    respond_to do |format|
      if @show_item.update_attributes(show_item_params)
        format.html { redirect_to @show_item, notice: "Show item was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @show_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /show_items/1
  # DELETE /show_items/1.json
  def destroy
    @show_item = ShowItem.find(params[:id])
    @show_item.create_activity action: "destroy", owner: current_user, parameters: { show: @show_item.show.id.to_s }

    # if we remove an item from a show we must reorder the show.
    if @show_item.destroy
      n = 1
      @show_items = ShowItem.where(show_id: @show_item.show_id).asc(:seq)
      @show_items.each { |si|
        si.seq = n
        n = n + 1
        si.save
      }
    end

    PublicActivity.enabled = false
    @show = Show.find(@show_item.show_id)
    @show.showitem_seq = n
    @show.save
    PublicActivity.enabled = true

    respond_to do |format|
      format.html { redirect_to show_items_url }
      format.json { head :no_content }
    end
  end

  private

  def show_item_params
    params.require(:show_item).permit(:kind, :seq, :duration, :time, :note, :color, :show_id, :act_id)
  end


  def is_numeric?(s)
    s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  end
end
