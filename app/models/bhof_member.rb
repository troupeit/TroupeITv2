class BhofMember
  include Mongoid::Document
  include Mongoid::Timestamps

  # pagination gem doesn't work?
  # paginates_per 20

  field :first_name, type: String
  field :last_name, type: String
  field :memberid, type: Integer
  field :email, type: String

  field :wa_creation_date, type: Date
  field :membership_status, type: String

  field :renewal_due, type: Date
  field :member_since, type: Date
end
