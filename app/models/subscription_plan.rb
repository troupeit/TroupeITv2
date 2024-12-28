class SubscriptionPlan
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :companies

  field :stripe_id, type:  String
  field :name, type:  String
  field :short_name, type:  String
  field :description, type:  String
  field :amount, type:  Integer
  field :interval, type:  String
  field :interval_count, type:  Integer, default:  1
  field :events_per_month, type:  Integer
  field :crew_size, type:  Integer
  field :performer_limit, type:  Integer
  field :file_storage, type:  Integer
  field :active, type:  Boolean
end
