class Apikey
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :name, type:  String

  # pin is only valid for 30 minutes after generation
  field :temppin, type:  String
  field :secret, type:  String

  field :valid_for_auth, type:  Boolean, default:  false
end
