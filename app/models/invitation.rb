class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps

  validates_presence_of :company_id
  validates_presence_of :type

  before_create :generate_token

  # this thing is probably way more complicated than it needs to be,
  # but we have to handle special cases.

  belongs_to :sender, class_name: "User"

  # 0 = company invitation (user to user)
  # 1 = company invitation (user to email)
  # 128 = system invitation (created at time of company creation)
  field :type, type:  Integer, default: 

  field :email, type:  String
  field :company_id
  field :valid_until, type:  DateTime

  field :token, type:  String
  field :used, type:  Boolean, default:  false
  field :single_use, type:  Boolean, default:  true

  field :access_level, type:  Integer, default: 
  field :use_count, type:  Integer, default:  0

  def generate_token
    self.token = SecureRandom.hex(8)
  end
end
