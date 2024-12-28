class Show
   # A show, consisting of many show items...
   # essentially the spreadsheet joyce makes now.
   include Mongoid::Document
   include Mongoid::Timestamps
   include PublicActivity::Model

   tracked except: [:update],
           owner: Proc.new{ |controller, model| controller.current_user },
           :params => {
             :title => proc {|controller, model| (model.title)}
           }
  
   after_save :update_event_dates
   before_destroy :update_and_delete
   belongs_to :event

   has_many :show_items, dependent: :destroy, :order => :seq.asc
   has_many :show_item_notes, dependent: :destroy

   validates_presence_of :title
   validates_presence_of :show_time
   validates_presence_of :door_time
   validates_presence_of :venue
   validates_presence_of :event_id

   field :title, type:  String
   field :venue, type:  String
   field :goog_place_id, type:  String

   field :room, type:  String

   field :show_time, type:  Time
   field :door_time, type:  Time

   # live show functions
   field :emergency_msg, type:  String
   field :highlighted_row, type:  String
   field :highlighted_at, type:  DateTime

   # record last download time so we can warn users if a download has
   # occurred before show changes are settled
   field :last_download_at, type:  DateTime
   belongs_to :last_download_by, class_name: "User"

   # item sequences always start at one.
   field :showitem_seq, type:  Integer, default: 

   # have we sms'd this show out?
   field :notifications_sent, type:  Boolean, default:  false

   private

   def update_and_delete
     update_event_dates(true) 
   end

   def update_event_dates(deleting = false)
     logger.debug("post show update is firing")

     # housekeeping function to recalculate event start and end times based on event data.
     # needs to happen after every show save, and after every showitem modification.
     #
     # if deleting is true, we will act as if the current show does not exist.
     # it is the caller's duty to notify other users after this occurs. 

     mindate = nil
     maxdate = nil

     theevent = Event.find(self.event_id)
     origstart = theevent.startdate
     origend = theevent.enddate

     shows = Show.where(event_id: theevent.id)

     # if we delete everything, clear the dates. 
     if shows.count == 0
       theevent.startdate = nil
       theevent.enddate = nil
       theevent.submission_deadline = nil
       theevent.save
       return
     end

     shows.each { |s|
       next if s.id == self.id and deleting
       
       if mindate.nil? or s.door_time <= mindate
         mindate = s.door_time
       end
       
       show_length = ShowItem.where({ show_id: self.id }).sum(:duration)
       end_time = s.door_time + show_length.seconds
       
       if maxdate.nil? or end_time >= maxdate
         maxdate = end_time
       end
     }

     if mindate != origstart or maxdate != origend or origstart.nil? or origend.nil?
       theevent.startdate = mindate
       theevent.enddate = maxdate

       # we may be writing nil's here. disable validation.
       if theevent.save(validate: false)
         logger.debug("Updated: Show #{self.id} Save: Event #{self.event_id} with end time #{theevent.enddate}")
       else
         logger.debug("Update FAILED: Show #{self.id} Save: Event #{self.event_id} with end time #{theevent.enddate}")
       end
     else
       logger.debug("No Change: Show #{self.id} Save: Event #{self.event_id} with end time #{theevent.enddate}")
     end
  end
end
