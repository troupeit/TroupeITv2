class Company
  include Mongoid::Document
  include Mongoid::Timestamps
  # include ActsAsTaggable::Tagger

  belongs_to :user
  belongs_to :subscription_plan

  has_many :company_memberships, dependent: :destroy
  has_many :events, dependent: :destroy

  validates_presence_of :name, :description
  validates_uniqueness_of :name

  field :name, type: String
  field :description, type: String
  field :long_description, type: String

  field :private, type: Boolean, default: true
  field :invite_required, type: Boolean, default: true
  field :members_can_invite, type: Boolean, default: false

  field :last_payment, type: DateTime
  field :paid_through, type: DateTime
  field :payment_failed, type: Boolean, default: false

  # this is a double-write field here. we write customer ID to company and user.
  field :stripe_customer_id, type: String
  field :stripe_subscription_id, type: String

  # images
  field :cover_uuid, type: String
  field :avatar_uuid, type: String

  #
  # careful here; Company.users = users that belong to the company.
  # Company.user_id = user who owns company.
  #
  def users
    User.in(id: company_memberships.map(&:user_id))
  end

  def user_can_invite?(auser)
    suspect = User.find(auser.id)

    if self.user_id == suspect.id  # owner
      return true
    end

    if self.members_can_invite && suspect.in(id: self.company_memberships.map(&:user_id)) # member
      true
    end
  end

  def has_member?(user)
    # pass in a user and we'll tell you if that person is a member or not.
    CompanyMembership.all_of(company: self, user: user).count > 0
  end

  def make_comp!
    # make a company complimentary access forever
    self.paid_through = Date.parse("1-1-2099 00:00:00")
    s = SubscriptionPlan.where(short_name: "COMP").first
    self.subscription_plan = s
    self.save
  end
end
