class Decider
  include Mongoid::Document

  validates_presence_of :key, :value_f, :value_f_staging, :value_f_test

  validates_numericality_of :value_f, greater_than_or_equal_to: 0, less_than_or_equal_to: 1
  validates_numericality_of :value_f_staging, greater_than_or_equal_to: 0, less_than_or_equal_to: 1
  validates_numericality_of :value_f_test, greater_than_or_equal_to: 0, less_than_or_equal_to: 1

  field :key, type: String

  # what does it do?
  field :description, type: String

  # Value used when RAILS_ENV is production
  field :value_f, type: Float

  # Value used when RAILS_ENV is staging
  field :value_f_staging, type: Float

  # Value used when RAILS_ENV is test
  field :value_f_test, type: Float
end
