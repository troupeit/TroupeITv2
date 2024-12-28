module SubmissionTools
  class << self
    def get_events_accepting(current_user)
      # return a list of all events that are accepting submissions in the user's companies
      @accepting = []
      current_user.company_memberships.each { |c|
        @events = Event.where({ company: c.company_id }).gte({ accepting_from: 1 }).order_by(startdate: :asc)
        @events.each { |e|
          # we auto-close submissions after the start date.
          if e.startdate.present?
            if (e.submission_deadline.nil? and e.startdate >= DateTime.now) or (e.submission_deadline.present? and e.submission_deadline >= DateTime.now)
              @accepting << e
            end
          end
        }
      }

      @accepting
    end
  end
end
