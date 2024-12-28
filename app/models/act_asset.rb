class ActAsset
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :act
  belongs_to :passet
  validates_presence_of :seq

  # sequence in this act 
  field :seq, type:  Integer
  
end
