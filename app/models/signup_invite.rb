class SignupInvite
  include Mongoid::Document
  include Mongoid::Timestamps

  validates_presence_of :code

  # human readable signup/discount codes that can be handed out to people.
  field :code, type:  String

  # nil = no limit
  field :available, type:  Integer

  # nil = no expiry
  field :expires, type:  DateTime

  field :used_count, type:  Integer, default:  0
  # todo: discount... etc...

  # feature to randomize, here if needed, but we default to nothing.
  def generate_code
    self.code = SecureRandom.hex(3)
  end
end
