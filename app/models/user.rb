class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActsAsTaggable::Tagger

  include PublicActivity::Model
  activist

  after_create :reset_trial_expiration

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :omniauthable

  # dependent objects
  has_many :acts, dependent: :destroy
  has_many :passets, dependent: :destroy
  has_many :apps, dependent: :destroy
  has_many :company_memberships, dependent: :destroy
  has_many :event_submissions, dependent: :destroy
  has_many :companies, class_name: "Company", dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", dependent: :destroy
  has_many :bhofreviews, inverse_of: :judge
  has_many :show_item_notes
  has_many :apikeys
  has_many :resetkeys

  has_many :shows, inverse_of: :last_download_by

  # Role-Based Access Control
  has_and_belongs_to_many :roles
  # has_one_time_password

  # validations
  validates_presence_of :email, message: "You must supply an e-mail address."
  validates_email_format_of :email, message: "Invalid e-mail address."
  validates_presence_of :encrypted_password
  validates_presence_of :name, message: "We need your full name."
  validates_presence_of :username, message: "User name is required."
  validates :username, { length: { minimum: 3, maximum: 25 } }

  # these must be valid image file names or we won't store them.
  validates_format_of :cover_uuid, with: /\A[0-9a-f-]+\.[a-zA-Z]+\Z/, allow_blank: true
  validates_format_of :avatar_uuid, with: /\A[0-9a-f-]+\.[a-zA-Z]+\Z/, allow_blank: true

  ## Database authenticatable
  field :email,              type:  String, default: ""
  field :email_valid,        type:  Boolean, default: true
  field :encrypted_password, type:  String, default: ""

  ## OmniAuth Integration
  field :provider,           type:  String, default: ""
  field :uid,                type:  String, default: ""
  field :time_zone,          type:  String, default: "Pacific Time (US & Canada)"

  ## SMS Integration
  field :phone_number,       type:  String, default:  ""
  field :sms_capable,        type:  Boolean, default:  false      # if number has SMS
  field :sms_confirmed,      type:  Boolean, default:  false      # if we've confirmed them

  field :sms_confirmation_code, type:  String    # six digit confirmation code
  field :sms_notifications,  type:  Boolean      # if notifications are enabled by the user
  field :sms_sleep_enabled,  type:  Boolean

  field :sms_sleep_start_hh, type:  Integer      # during this period we will not message you.
  field :sms_sleep_end_hh,   type:  Integer

  ## Recoverable
  field :reset_password_token,   type:  String
  field :reset_password_sent_at, type:  Time

  ## Rememberable
  field :remember_created_at, type:  Time

  ## Trackable
  field :sign_in_count,      type:  Integer, default:  0
  field :current_sign_in_at, type:  Time
  field :last_sign_in_at,    type:  Time
  field :current_sign_in_ip, type:  String
  field :last_sign_in_ip,    type:  String

  field :trial_expires_at,   type:  Time
  field :trial_extended,     type:  Boolean, default:  false

  field :username, type:  String

  field :admin, type:  Boolean, default:  false

  # if true, disables the tutorials
  field :disable_tutorial, type:  Boolean, default:  false

  # uuid of avatar and cover image plus extension of file
  field :cover_uuid, type:  String
  field :avatar_uuid, type:  String

  ## Confirmable
  field :confirmation_token,   type:  String
  field :confirmed_at,         type:  Time
  field :confirmation_sent_at, type:  Time
  field :unconfirmed_email,    type:  String # Only if using reconfirmable

  ## profile
  field :location,             type:  String
  field :miniresume,           type:  String

  ## Privacy
  field :share_phone,     type:  Boolean, default:  false
  field :share_email,     type:  Boolean, default:  false

  ## Lockable
  # field :failed_attempts, type:  Integer, default:  0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type:  String # Only if unlock strategy is :email or :both
  # field :locked_at,       type:  Time

  ## Token authenticatable
  # field :authentication_token, type:  String

  field :otp_secret_key,    type:  String
  field :otp_required,      type:  Boolean, default:  false

  # so, here's the thing. This turns on tinfoil security's gem (devise-two-factor)
  # which we do NOT want turned on. We're using it only for otp_backup_codes
  #
  # In a perfect world, someone will merge these two gems, but I'm not doing it.
  #
  field :second_factor_attempts_count, type:  Integer, default:  0
  field :name

  # what invite code did they use?
  field :used_code, type:  String

  # preferences for live view
  field :live_view_columnpref, type:  String, default:  "[0,1,2,3,4,5,6,7]"

  # email preferences
  field :email_product_updates, type:  Boolean, default:  true
  field :email_notifications, type:  Boolean, default: true
  field :email_marketing, type:  Boolean, default: true

  # this represents the email lifecycle
  field :emailed_welcome, type:  Boolean, default:  false
  field :emailed_post_welcome, type:  Boolean, default:  false
  field :emailed_trial_ends_soon, type:  Boolean, default:  false
  field :emailed_trial_over, type:  Boolean, default:  false
  field :emailed_trial_over_nudge,  type:  Boolean, default:  false
  field :emailed_resurrect1, type:  Boolean, default:  false
  field :emailed_resurrect2, type:  Boolean, default:  false

  field :stripe_customer_id, type:  String
  field :bhof_member_id, type:  Integer

  # support soft deletes
  field :deleted_at, type:  Time

  # Indexes
  index({ username: 1 }, { unique: true })
  index({ email: 1 }, { unique: true })

  # Exclude key info from json output.
  def to_xml(options = {})
    options[:except] ||= [ :otp_required, :otp_secret_key, :second_factor_attempts_count, :used_code ]
    super(options)
  end

  def as_json(options = {})
    options[:except] ||= [ :otp_required, :otp_secret_key, :second_factor_attempts_count, :used_code ]
    super(options)
  end

  def send_two_factor_authentication_code
    # this is a noop for use as people will use the authenticator...
  end

  def xauth_token
    # this generates a token for establishing trust between our servers
    # it should never be used externally. It serves as a weak authentication back to node.js
    # SECURITY: this needs an external dependency like week, or time, or something.
    OpenSSL::HMAC.digest("sha256", Rails.application.credentials.xauth_secret, self.id.to_s).unpack("H*").first
  end

  def need_two_factor_authentication?(request)
    self.otp_required
  end

  def has_role?(role_sym)
    roles.each { |r|
      if r.name.underscore.to_sym == role_sym
        return true
      end
    }
    false
  end

  def self.find_for_facebook_oauth(auth, signed_in_resource = nil)
    logger.debug("find for fb :provider => #{auth.provider}, :uid => #{auth.uid}")
    return_user = User.where(provider: auth.provider, uid: auth.uid).first
    unless return_user
      if self.where(email: auth.info.email).exists?
        logger.debug("fbauth: user with email #{auth.info.email} exists -- connecting")
        return_user = self.where(email: auth.info.email).first
        return_user.provider = auth.provider
        return_user.uid = auth.uid
      else
        logger.debug("fbauth: creating a new user")
        email_valid = true

        if auth.info.email.present?
          email = auth.info.email
        else
          email = "#{auth.uid}-fb@example.org"
          email_valid = false
        end

        return_user = User.create(username: auth.extra.raw_info.name.clone,
                                  name: auth.extra.raw_info.name,
                                  provider: auth.provider,
                                  uid: auth.uid,
                                  email: email,
                                  email_valid: email_valid,
                                  password: Devise.friendly_token[0, 20]
                                 )
        return_user.save!
      end
    end
    return_user
  end

  def self.find_for_twitter_oauth(auth, signed_in_resource = nil)
    logger.debug("find for twitter :provider => #{auth.provider}, :uid => #{auth.uid}")
    return_user = User.where(provider: auth.provider, uid: auth.uid).first
    unless return_user
      logger.debug("twitterauth: creating a new user")
      logger.debug(auth.extra)
      return_user = User.create(username: auth.extra.raw_info.name.clone,
                                name: auth.extra.raw_info.name,
                                provider: auth.provider,
                                uid: auth.uid,
                                email: "#{auth.extra.raw_info.screen_name}-tw@example.org",
                                email_valid: false, # twitter never sends us an email
                                password: Devise.friendly_token[0, 20]
                               )
      return_user.save!
    end
    return_user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def profile_img_url(size)
    if size.nil?
      size="normal"
    end

    if self.provider == "facebook"
      "https://graph.facebook.com/#{self.uid}/picture?type=#{size}"
    else
      ""
    end
  end

  def reset_trial_expiration
    self.trial_expires_at = Time.now + (86400 * 30)
    self.save
  end


  def first_name
    self.name.split.first
  end

  def last_name
    if self.name.split.count > 1
      self.name.split[1..-1].join(" ")
    end
  end

  # instead of deleting, indicate the user requested a delete & timestamp it
  def soft_delete
    update_attribute(:deleted_at, Time.current)
  end

  # ensure user account is active
  def active_for_authentication?
    super && !deleted_at
  end

  # provide a custom message for a deleted account
  def inactive_message
    !deleted_at ? super : :deleted_account
  end

  # if this user has any companies that they have paid for.
  def has_paid?
    paid = false
    self.companies.each { |c|
      if c.paid_through.present?
        if c.paid_through >= Time.now
          paid = true
        end
      end
    }

    paid
  end

  def has_ever_paid?
    ever_paid = false
    self.companies.each { |c|
      if c.paid_through.present?
        ever_paid = true
      end
    }
    ever_paid
  end

  def can_receive_sms?
    self.phone_number.present? and self.sms_capable and self.sms_confirmed
  end

  def sms_ok_now?
    if self.sms_notifications and self.can_receive_sms?
      if self.sms_sleep_enabled
        t = Time.now.in_time_zone(self.time_zone)
        if t.hour >= self.sms_sleep_start_hh and t.hour <= sms_sleep_end_hh
          return false
        else
          return true
        end
      else
        return true
      end
    end
    false
  end
end
