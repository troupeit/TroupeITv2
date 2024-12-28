# Repair and housekeeping scripts

# Tasks in this file MUST be working against the current source code
# and be non-damaging to the service.

# Remove any repair tasks that do not work/don't make sense

# use sensible short names such that "rake repair:thing" works

namespace :repair do
  task hubba_titles: :environment do
    Show.all.each { |s|
      s.title = s.title.gsub(/Hubba Hubba Revue\s*-\s*/i, "")
      s.title = s.title.gsub(/Hubba Hubba Revue[ ]*:[ ]*/i, "")
      s.title = s.title.gsub(/Hubba Hubba-/i, "")
      s.title = s.title.titleize

      puts s.title
      s.save!
    }

    Event.all.each { |e|
      e.title = e.title.gsub(/Hubba Hubba Revue\s*-\s*/i, "")
      e.title = e.title.gsub(/Hubba Hubba Revue[ ]*:[ ]*/i, "")
      e.title = e.title.gsub(/Hubba Hubba-/i, "")
      e.title = e.title.titleize
      puts e.title

      e.save!
    }
  end

  task sequences: :environment do
    PublicActivity.enabled = false
    shows = Show.all.each { |s|
      seq = 1
      puts "---"
      puts "#{s.id} #{s.title} max #{s.showitem_seq}"
      puts "---"
      items = s.show_items.each { |si|
        puts "  #{si.seq} - #{si.id}"
        if si.seq != seq
          puts "WARNING - should be #{seq}"
          si.seq = seq
          si.save!
        end
        seq += 1
      }

      if s.showitem_seq != seq
        puts "MAX WRONG"
        PublicActivity.enabled = false
        s.showitem_seq = seq
        s.save!
      end
    }
  end

  task showitems: :environment do
    # find and destroy show items with no shows
    n = 0
    ShowItem.all.each { |si|
      if si.show_id.present?
        n = n + 1

        begin
          s = Show.find(si.show_id)
        rescue Mongoid::Errors::DocumentNotFound
          puts "Orphaned Show Item #{si.id} -- referenced show #{si.show_id} does not exist. Removing item"
          si.destroy
        end
      end

      if si.act_id.present? and si.act_id != 0
        begin
          a = Act.find(si.act_id)
        rescue Mongoid::Errors::DocumentNotFound
          puts "Show Item #{si.id} is holding nonexistent act #{si.act_id}"
        end
      end
    }

    puts "Checked #{n} records. OK."
  end

  task phone_cleanup: :environment do
    User.all.each { |u|
      if u.phone_number.present?
        puts "#{u.username} #{u.phone_number}"
        p = GlobalPhone.parse(u.phone_number.gsub(/^00/, "+"))
        if p.nil?
          puts "FAIL: #{u.id} #{u.username} #{u.phone_number}"
        else
          u.phone_number = p.international_format.gsub(" ", "").gsub("-", "")
          puts u.phone_number
          u.save
        end
        puts
      end
    }
  end

  # retry all failed assets
  task stuck_passets: :environment do
    Passet.all_of({ :created_at.gte => (Time.now - 10.minutes) },
                  { processed: 0 }).each { |p|
      p.post_process!
    }
  end
end
