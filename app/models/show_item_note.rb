class ShowItemNote
  include Mongoid::Document
  include Mongoid::Timestamps

  KIND_COMPANY = 0
  KIND_PRIVATE = 1
  
  belongs_to :show_item
  belongs_to :user
  belongs_to :show

  validates_presence_of :show_item
  validates_presence_of :user
  validates_presence_of :show

  field :note, type:  String
  field :kind, type:  Integer
end
