class Lead
  # a lead is an email address or other data from someone who isn't
  # using the service yet that we'd like to track.

  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type:  String
  field :email, type:  String

  field :contacted, type:  Boolean, default:  false
  field :invited, type:  Boolean, default:  false

  def first_name
    self.name.split.first
  end

  def last_name
    if self.name.split.count > 1
      self.name.split[1..-1].join(" ")
    end
  end
end
