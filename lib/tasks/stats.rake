namespace :stats do
  desc "Update user statistics"

  task update_datadog: :environment do
    # these are application database statistics which don't change too
    # often.  we run this job every ten minutes or so, but could run
    # it hourly. The idea is to track this over time to gauge growth.

    # total number of users
    StatsD.gauge("troupeit.users.count", User.count)

    # in trial
    StatsD.gauge("troupeit.users.in_trial", User.where({ :trial_expires_at.gte  => Time.now }).count)

    # no trial
    StatsD.gauge("troupeit.users.no_trial", User.where({ trial_expires_at: nil }).count)

    # Active Sign Ins
    StatsD.gauge("troupeit.users.active_30", User.where({ :current_sign_in_at.gte  => (Time.now - 30.days) }).count)
    StatsD.gauge("troupeit.users.active_60", User.where({ :current_sign_in_at.gte  => (Time.now - 60.days) }).count)
    StatsD.gauge("troupeit.users.active_90", User.where({ :current_sign_in_at.gte  => (Time.now - 90.days) }).count)

    # MAU, the right way (by visits)
    StatsD.gauge("troupeit.visits.distinct_30", Visit.where({ :started_at.gte  => (Time.now - 30.days) }).distinct(:user_id).count)
    StatsD.gauge("troupeit.visits.distinct_60", Visit.where({ :started_at.gte  => (Time.now - 60.days) }).distinct(:user_id).count)
    StatsD.gauge("troupeit.visits.distinct_90", Visit.where({ :started_at.gte  => (Time.now - 90.days) }).distinct(:user_id).count)

    # Visits by user
    StatsD.gauge("troupeit.visits.indistinct_30", Visit.where({ :started_at.gte  => (Time.now - 30.days), :user_id.ne => nil }).count)
    StatsD.gauge("troupeit.visits.indistinct_60", Visit.where({ :started_at.gte  => (Time.now - 60.days), :user_id.ne => nil }).count)
    StatsD.gauge("troupeit.visits.indistinct_90", Visit.where({ :started_at.gte  => (Time.now - 90.days), :user_id.ne => nil }).count)

    # signups today (UTC)
    StatsD.gauge("troupeit.users.signups_today", User.where({ :created_at.gte  => Time.now.beginning_of_day }).count)

    # paid
    paid = 0
    valid_companies = Company.where({ :paid_through.gte  => Time.now })
    valid_companies.each { |vc|
      if vc.subscription_plan
        if vc.subscription_plan.short_name != "COMP"
          paid = paid + 1
        end
      end
    }
    StatsD.gauge("troupeit.companies.paid", paid)

    # companies that exist
    StatsD.gauge("troupeit.companies.count", Company.count)

    # events that exist
    StatsD.gauge("troupeit.events.count", Event.count)

    # shows
    StatsD.gauge("troupeit.shows.count", Show.count)

    # show items
    StatsD.gauge("troupeit.show_items.count", ShowItem.count)

    # acts
    StatsD.gauge("troupeit.acts.count", Act.count)

    # apps
    StatsD.gauge("troupeit.apps.count", App.count)

    # assets
    StatsD.gauge("troupeit.passets.total", Passet.count)
    StatsD.gauge("troupeit.passets.stuck", Passet.where({ processed: 0 }).count)

    # MRR
    # Churn
    # Cost per acquisition
    # Average Revenue Per Customer
  end
end
