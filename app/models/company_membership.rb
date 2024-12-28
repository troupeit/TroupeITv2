class CompanyMembership
  include Mongoid::Document
  include Mongoid::Timestamps
  include PublicActivity::Model

  tracked except: [ :update ],
          owner: Proc.new { |controller, model| controller.current_user },
          :params => {
            :company_name => proc { |controller, model| (model.company.name) }
           }

  # has_many_through style table showing what users belong to what company names

  belongs_to :user
  belongs_to :company

  # 0 = "performer" / read only crew, cannot change anything
  # 2 = "Tech Crew" / can download, other things TBD
  # 4 = "Stage Manager" / can change show data, but cannot add shows.
  # 8 = "Producer" -- can create new events in company, can change anything

  field :sort_name, type:  String
  field :sort_username, type:  String
  field :access_level, type:  Integer, default:  0

  def self.is_cohort?(usera, userb)
    # returns true if usera and userb are in any companies together
    begin
      ua = User.find(usera)
      ub = User.find(userb)
    rescue
      return false
    end

    ua.company_memberships.each { |ca|
      ub.company_memberships.each { |cb|
        if cb.company_id == ca.company_id
          return true
        end
      }
    }

    false
  end
end
