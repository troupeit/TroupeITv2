class Event
  include Mongoid::Document
  include Mongoid::Timestamps
  include PublicActivity::Model

  tracked owner: Proc.new{ |controller, model| controller.current_user },
          :params => {
             :title => proc {|controller, model| (model.title)}
           }

  field :title, type: String
  field :startdate, type: DateTime
  field :enddate, type: DateTime
  field :submission_deadline, type: DateTime
  
  # message of the day on the event page
  field :motd_changed_at, type: DateTime
  field :motd, type: String, default: ""

  # 0 = No one, 1 = company, 2 = public
  field :accepting_from, type: Integer, default: 1
  field :time_zone, type:  String, :default => "US/Pacific"
  validates_presence_of :title, :startdate, :enddate, :company

  # Don't call the show before_destroy call back (delete vs. destroy)
  # if the event goes away, because we're removing all shows.
  has_many :shows, dependent: :destroyy_all
  has_many :tasks, dependent: :destroy
  
  belongs_to :company

  has_many :event_submissions, dependent: :destroy
end
