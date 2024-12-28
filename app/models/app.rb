include ::AppsHelper

class App
  include Mongoid::Document

  has_many :bhofreviews, dependent: :destroy

  # a bhof member id that this is associated with
  field :memberid, type: Integer
  field :no_memberid, type: Mongoid::Boolean
  
  # this would indicate the year
  field :event_code, type: String
  
  field :legal_name, type: String
  field :mailing_address, type: String
  field :phone_primary, type: String
  field :phone_alt, type: String
  field :phone_primary_has_sms, type: Mongoid::Boolean
  field :legal_accepted, type: Mongoid::Boolean

  field :created_at, type:  DateTime
  field :updated_at, type: DateTime

  field :created_by, type:  String
  field :description, type:  String

  # paypal integration
  field :purchase_ip, type:  String
  field :purchased_at, type:  DateTime
  field :express_token, type:  String
  field :express_payer_id, type:  String
  field :purchase_price, type:  Float  # this is in cents!! Not dollars!

  # stripe integration (2016)
  field :stripe_customer_id, type:  String
  field :stripe_invoice_id, type:  String  # verify that we're using invoices... 

  field :is_group, type:  Mongoid::Boolean # false if solo

  # upon submit, we lock the app. changes locked out after this point
  field :locked, type:  Mongoid::Boolean
  field :forward_for_review, type:  Integer, :default => -1
  field :final_decision, type:  Integer, :default => 0

  # true if the applicant is in, and has has accepted our decision
  field :decision_rsvp, type:  Integer, :default => -1 

  # social media stuffs
  field :sm_facebook, type:  String
  field :sm_twitter, type:  String
  field :sm_instagram, type:  String
  
  validates_presence_of :legal_name, :mailing_address, :phone_primary, :phone_primary_has_sms, :description, :message => "Required"

  validates_inclusion_of :legal_accepted, :in => [true], :message => "You must check this box to accept the agreement"
  
  validates_format_of :phone_primary,
        :message => "You must enter a valid telephone number",
        :with => /\A[\(\)0-9\- \+\.]{10,20} *[extension\.]{0,9} *[0-9]{0,5}\z/

  belongs_to :user
  embeds_one :entry, autobuild: true
  embeds_one :entry_techinfo, autobuild: true

  has_one :entry, dependent: :destroy
  has_one :entry_techinfo, dependent: :destroy

  def is_complete?
    # true if the initial part of the application is complete
    if self.legal_name.present? and
        self.mailing_address.present? and
        self.phone_primary.present? and
        self.legal_accepted == true
     return true
    end

    false
  end

  def purchase
    response = EXPRESS_GATEWAY.purchase(self.purchase_price, express_purchase_options)
    self.update_attribute(:purchased_at, Time.now) if response.success?
    response.success?
  end

  def express_token=(token)
    self[:express_token] = token
    if new_record? && !token.blank?
      # you can dump details var if you need more info from buyer
      details = EXPRESS_GATEWAY.details_for(token)
      self.express_payer_id = details.payer_id
    end
  end

  # calculate the purchase price for this app based on the current time
  def get_current_price
    #  Safety: We'll never charge less than $29.00. I'd set this to zero, but um, no.
    rate = 2900

    BHOF_RATES.each { |bh|
      if Time.now() >= bh[:deadline]
        rate = bh[:rate]
      end
    }
    rate
  end

  def complete?
    # true if the application and it's subcomponents are complete
    if self.entry and self.entry_techinfo and self.is_complete? and self.entry.is_complete? and self.entry_techinfo.is_complete? and self.purchased_at.present? 
      true
    else
      false
    end
  end 

  def self.to_csv

    # include all of the associated entry fields
    keys = App.fields.keys
    Entry.fields.keys.each do |ek|
      keys.push("entry-" + ek)
    end

    # extra entry fields
    keys.push('type')
    keys.push('category')
    keys.push('compete_preference')

    # include a limited set of user fields
    user_fields = ['email','name','username']
    user_fields.each do |ek|
      keys.push("user-" + ek)
    end

    CSV.generate do |csv|
      csv << keys
      all.each do |app|
        row = app.attributes.values_at(*App.fields.keys)

        if app.entry
          row = row + app.entry.attributes.values_at(*Entry.fields.keys)
          row << AppsHelper.type_to_s(app.entry.type)
          row << AppsHelper.cat_to_s(app.entry.category)
          row << AppsHelper.compete_to_s(app.entry.compete_preference)
        end

        if app.user
          row = row + app.user.attributes.values_at(*user_fields)
        end

        csv << row

      end
    end
  end

  private

  def express_purchase_options
    {
      :ip => purchase_ip,
      :token => express_token,
      :payer_id => express_payer_id
    }
  end

end
