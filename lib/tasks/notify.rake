namespace :notify do
  desc "SMS upcoming show"

  task sms_preshow: :environment do
    # find all of the shows in the next two hours
    # for each show
    #    Message all of the producers of the company
    #    Message all of the people in that show

    now = Time.now
    shows = Show.where({ :door_time.lte => now + 5.hours,
                         :door_time.gte => now,
                         :notifications_sent => false })

    shows.each { |s|
      puts s.title
      puts s.door_time
      puts s.event.company

      members = CompanyMembership.where({ company_id: s.event.company })
      # notify the company producers
      members.each { |m|
        if m.access_level > 0
          if m.user.can_receive_sms? and m.user.sms_ok_now?
            puts m.user.name
            msg =  "TroupeIT: CREW: #{s.event.company.name}:#{s.title} happens today. Doors #{s.door_time.in_time_zone(s.event.time_zone).strftime(TIME_ONLY_FMT_TZ).squish}"
            puts msg
            puts msg.length
            TwilioMsg.message_user(m.user, msg)
          end
        end
      }

      # notify the performers in this show
      curtime = s.door_time
      s.show_items.each { |si|
        if si.act.present?
          if si.act.user.can_receive_sms? and si.act.user.sms_ok_now?
            localized_time = curtime.in_time_zone(s.event.time_zone).strftime(TIME_ONLY_FMT_TZ).squish
            puts si.act.user.name
            msg =  "TroupeIT: #{s.event.company.name}:#{s.title} is today! Your performance is at #{localized_time}."
            puts msg
            puts msg.length

            TwilioMsg.message_user(si.act.user, msg)
          end
          curtime = curtime + si.duration
        end
      }
      s.notifications_sent = true
      s.save
    }
  end
end
