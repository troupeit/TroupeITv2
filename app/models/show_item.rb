class ShowItem
  include Mongoid::Document
  include Mongoid::Timestamps
  include PublicActivity::Model
  
  after_save :update_event_dates
  after_save :update_show_updated_at
  
  belongs_to :show
  validates_presence_of :kind

  KIND_NOTE = 0
  KIND_ASSET = 32
  
  field :kind, type:  Integer

  # sequence in this show
  field :seq, type:  Integer

  # act_id is zero if note.
  field :old_act_id, type:  String
  belongs_to :act
  has_many :show_item_notes, dependent: :destroy
  
  # The way we handle times is as follows:
  #
  # if a time is set here, we use it, That's a 'fixed' time reference.
  # else
  #   if this is an asset, we use the duration from the asset.
  #   else
  #     this is a note, use the duration from here
  #
  field :duration, type:  Integer    # in seconds

  # not used yet...
  field :time, type:  Time

  # extra note from the showadmin
  field :note, type:  String

  field :color, type:  String

  def title
    if self.kind == ShowItem::KIND_NOTE
      return self.note
    end

    if self.kind == ShowItem::KIND_ASSET
      if not  self.act.title.nil?
        return self.act.stage_name + ": " + self.act.title
      else
        return self.act.stage_name
      end
    end
  end

  # return a specific note for an event's show
  def get_note(current_user,kind)
    if self.show_item_notes.blank?
      return nil
    end

    self.show_item_notes.each { |n|
      if n.kind == ShowItemNote::KIND_COMPANY and kind == ShowItemNote::KIND_COMPANY
          return n.note
      end

      if n.kind == ShowItemNote::KIND_PRIVATE and kind == ShowItemNote::KIND_PRIVATE and n.user_id == current_user.id
          return n.note
      end
    }

    return ""
  end
  
  
  private

  def update_event_dates
    # housekeeping function to recalculate event start and end times based on event data.
    # needs to happen after every show save, and after every showitem modification. 
    mindate = nil
    maxdate = nil

    show = Show.find(self.show_id)
    theevent = Event.find(show.event_id)
    shows = Show.where(event_id: theevent.id)

    origend = theevent.enddate

    # If you're adding, removing, or changing a show item, the only thing that can ever change
    # is the end of the show. The beginning can only be moved by a show.save which can't happen
    # here. So, we only recalc the end times of our show.

    shows.each { |s|
      show_length = ShowItem.where({ show_id: show.id }).sum(:duration)
      end_time = show.door_time + show_length.seconds
      
      if maxdate.nil? or end_time >= maxdate
        maxdate = end_time
      end
      
    }

    if maxdate != origend 
      theevent.enddate = maxdate
      # disable activity feed because this is an internal operation
      PublicActivity.enabled = false
      theevent.save
      PublicActivity.enabled = true
      
      logger.debug("ShowItem #{self.id.to_s} Save: Event #{show.event_id} with end time #{theevent.enddate}")
    end    
  end

  def update_show_updated_at
    # when a change happens to a show item, we must also update the parent data to trap changes
    PublicActivity.enabled = false
    show = Show.find(self.show_id)
    show.updated_at = Time.now
    show.save
    PublicActivity.enabled = true
  end

end
