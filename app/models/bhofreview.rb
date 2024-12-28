class Bhofreview
  include Mongoid::Document
  include Mongoid::Timestamps

  validates :score, numericality: { greater_than_or_equal_to: 0.0,
                                       less_than_or_equal_to: 10.0,
                                       message: "Score must be between 0.0 and 10.0" },  allow_nil: false

  validates :round, inclusion: { in: 1..3, message: "Round must be between 1 and 3" }


  belongs_to :judge, class_name: "User"
  belongs_to :app

  # which scoring round this belongs to
  field :round, type: Integer

  # score
  field :score, type: Float

  # can be blank
  field :comments, type: String

  # if this is true this score is ignored in all math but comments can be left (score should be set to 0.0 for these reviews)
  field :recused, type: Boolean, default:  false

  # uniqueness constraint - one review per judge
  index({ judge_id: 1, app_id: 1 }, { unique: true })
end
