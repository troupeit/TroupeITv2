class Act
   # An Act that a user owns, comprised of many assets and people
   # possibly not part of this system.
   include Mongoid::Document
   include Mongoid::Timestamps
   #   include ActsAsTaggable::Taggable
   include PublicActivity::Model

   tracked except: [ :update ],
           owner: Proc.new { |controller, model| controller.current_user },
           :params => {
             :title => proc { |controller, model| (model.stage_name) }
           }

   belongs_to :user
   belongs_to :show_item

   has_many :act_asset, dependent: :destroy, :order => :seq.asc
   has_many :event_submissions, dependent: :destroy

   validates_presence_of :stage_name, :short_description, :length
   validates_numericality_of :length, :greater_than  => 0, :only_integer => true, :message => "Length must be in the form HH:MM:SS or MM:SS and not be zero."

   # these fields required for part (1)
   field :stage_name, type:  String
   field :names_of_performers, type:  String
   field :contact_phone_number, type:  String
   field :length, type:  Integer     # length in seconds
   field :short_description, type:  String

   field :title, type:  String

   field :sound_cue, type:  String
   field :prop_placement, type:  String

   field :lighting_info, type:  String
   field :clean_up, type:  String
   field :mc_intro, type:  String
   field :run_through, type:  String
   field :extra_notes, type:  String

   def length_s
     if self.length == nil
       "00:00"
     else
       m = (self.length/60).floor
       s = self.length % 60
       sprintf("%d:%2d", m, s)
     end
   end
end
