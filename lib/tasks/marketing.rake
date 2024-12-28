
namespace :marketing do
  desc "Produce CSV of BHOF users"
  task bhof_mails: :environment do
    File.open("bhofmails.csv", "w+") do |f|
      App.all.each { |a|
        f.write "\"#{a.user.email}\",\"#{a.user.first_name}\",\"#{a.user.last_name}\"\n"
      }

      f.close
    end
  end

  desc "Produce CSV of ALL users"
  task all_mails: :environment do
    File.open("allmails.csv", "w+") do |f|
      CSV.open("allmails.csv", "wb") do |csv|
        User.all.each { |user|
          csv << [ user._id.to_s, user.username, user.name, user.first_name, user.last_name, user.email, user.created_at, user.last_sign_in_at, user.trial_expires_at ]
        }
      end
      f.close
    end
  end

  desc "Produce CSV of LEADS"
  task lead_mails: :environment do
    File.open("leadmails.csv", "w+") do |f|
      Lead.all.each { |a|
        f.write "\"#{a.email}\",\"#{a.first_name}\",\"#{a.last_name}\"\n"
      }

      f.close
    end
  end

  # ideally this runs Monthly.
  # MTWTFSS
  desc "Signups in last 3 days"
  task recent_signups: :environment do
    cutoff = Time.now + 25.days
    #    User.where({:created_at.gt => cutoff}).each do |u|
    # since we did not have mongoid timestamps turned on, we have to cheat
    # by leveraging the trial
    User.where({ :trial_expires_at.gt => cutoff }).each do |u|
      puts u.email
    end
  end

  desc "Expiring in next ten days"
  task expiring_soon: :environment do
    cutoff = Time.now - 10.days
    User.where({ :trial_expires_at.gt => cutoff }).each do |u|
      unpaid = Company.where({ user: u, paid_through: nil }).count
      puts "#{u.email} #{u.trial_expires_at} #{unpaid}"
    end
  end

  desc "Expiring in next ten days with companies"
  task expiring_companies: :environment do
    cutoff = Time.now - 10.days
    cnt = 0

    User.where({ :trial_expires_at.gt => cutoff }).each do |u|
      unpaid = Company.where({ user: u, paid_through: nil }).count
      if unpaid > 0
        puts "#{u.email} #{u.trial_expires_at} #{unpaid}"
        cnt = cnt + 1
      end
    end

    puts cnt
  end

  desc "Notify users who signed up in last 48 hours - run nightly"
  task notify_postwelcome: :environment do
    users = User.where({ :created_at.gte => (Time.now - 48.hours) })

    users.each do |u|
      if u.emailed_post_welcome == false and u.email_notifications == true
        fname = u.name.split[0]
        puts u.name
        begin
          TransMailer.post_welcome(u).deliver
          u.emailed_post_welcome = true
          u.save
        rescue SparkPost::DeliveryException => e
          puts e
          puts "SUPRESSED in notify_postwelcome: #{u.email}"
        end
      end
    end
  end


  desc "Notify users who have expired trials - run nightly"
  task notify_expired: :environment do
    users = User.where({ :trial_expires_at.lt => Time.now })

    users.each do |u|
      if u.emailed_trial_over == false and u.email_notifications == true
        fname = u.name.split[0]
        unpaid = Company.where({ user: u }).count
        puts "#{u.email} #{u.trial_expires_at} unpaid=#{unpaid}"
        begin
          TransMailer.trial_expired(u).deliver
          u.emailed_trial_over = true
          u.save
        rescue SparkPost::DeliveryException => e
          puts e
          puts "SUPRESSED in notify_expires: #{u.email}"
        end
      end
    end
  end

  desc "Notify users who have upcoming expirations - run nightly"
  task notify_expiring_soon: :environment do
    cutoff = Date.today + 7.days
    users = User.all_of({ :trial_expires_at.gte => Date.today, :trial_expires_at.lte => cutoff })

    users.each do |u|
      puts "CHECK: #{u.email} #{u.trial_expires_at}"
      if u.emailed_trial_ends_soon == false and u.emailed_trial_over == false and u.email_notifications == true
        fname = u.name.split[0]
        unpaid = Company.where({ user: u }).count
        puts "#{u.email} #{u.trial_expires_at} unpaid=#{unpaid}"
        begin
          TransMailer.trial_expires_soon(u).deliver
          u.emailed_trial_ends_soon = true
          u.save
        rescue SparkPost::DeliveryException => e
          puts e
          puts "SUPRESSED in expiring_soon: #{u.email}"
        end
      end
    end
  end

  desc "Give users with expired trials (and no logins in 60 days or more) a second chance"
  task resurrect_dead: :environment do
    n=0
    users = User.all_of({ :trial_expires_at.lte => Date.today, :last_sign_in_at.lte => Date.today - 60 })
    users.each do |u|
      if u.emailed_resurrect1 == false
        puts "#{u.email} #{u.trial_expires_at} #{u.emailed_resurrect1}"
        n=n+1
        begin
          TransMailer.resurrect(u).deliver
          u.emailed_resurrect1 = true
          u.save
        rescue SparkPost::DeliveryException => e
          puts e
          puts "SUPRESSED in resurrect_dead: #{u.email}"
        end
      end
    end

    puts n
  end
end
