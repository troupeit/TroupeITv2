class Resetkey
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  validates_presence_of :token

  field :token, type: String

  def generate_token!
    # should be done manually by the caller.
    self.token = SecureRandom.hex(16)
    self.save
  end
end
