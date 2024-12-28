class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  include PublicActivity::Model

  validates_presence_of :txt
  belongs_to :event

  field :txt, type:  String
  field :completed, type:  Boolean, default:  false
  field :seq, type:  Integer
end
