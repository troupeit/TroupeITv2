namespace :bhof do
  task import_apps: :environment do
    PublicActivity.enabled = false

    # this task is run once a year to import the approved applications
    # into the system as acts, which the users can then update and the
    # bhof stage managers can manipulate.
    BHOF_FINALTAG =  { 0 => "out",
                       1 => "sat_boylesque",
                       2 => "sat_largegrp",
                       3 => "sat_smallgrp",
                       4 => "sat_debut",
                       5 => "sat_MEW",
                       6 => "thu_msi",
                       7 => "thu_and_sat_alt",
                       8 => "sat_alt",
                       9 => "thu_alt",
                       10 => "fri" }

    BHOF_CATTAG = [ "", "female_mew", "female_debut", "boylesque" ]
    BHOF_COMPTAG = [ "", "compete_only", "showcase_only", "comp_or_showcase" ]

    bhof_company = Company.where(name: /^Burlesque Hall of Fame 2022$/i).first

    # jna 2022: right now we're going to migrate 2020 to 2022 because covid...
    # for ever application in the system, for this year...
    App.where(event_code: "bhof_weekend_2020").each { |app|
      # if they were accepted
      if app.final_decision > 0 and app.decision_rsvp > 0
        # create an act
        newact = Act.new
        # attach the act to the user who entered
        newact.user = app.user

        # populate as much of it as we can
        newact.stage_name = app.entry.name
        newact.names_of_performers = app.entry.all_performer_names
        newact.contact_phone_number = app.phone_primary
        newact.length = 240 # defaulting to 4 minutes for now, change later

        newact.title = app.description.titleize
        newact.short_description = app.description.titleize

        newact.sound_cue = app.entry_techinfo.sound_cue
        newact.lighting_info = app.entry_techinfo.lighting_needs
        newact.prop_placement = app.entry_techinfo.props

        newact.clean_up = app.entry_techinfo.breakdown_needs
        newact.mc_intro = app.entry_techinfo.mc_intro
        newact.extra_notes = app.entry_techinfo.other_tech_info

        # bump to 2022
        newact.event_code = "bhof_weekend_2022"

        if newact.save
           puts "ok. #{newact._id}"
        end

        # attach the act as a eventsubmission to BHOF
        es = EventSubmission.new
        es.event = Event.where(title: /^BHOF Weekender 2022$/i).first
        es.act = Act.find(newact._id)
        es.user = newact.user

        if es.save
           puts "es save ok"
        end

        # Tag it
        tags = [ "bhof", "bhof2022" ]

        if app.is_group == true
          tags.append("group")
        end

        # tag compete preference -------------------------------
        tags.append(BHOF_COMPTAG[app.entry.compete_preference])

        # tag cat pref ----------------------------------------
        if app.entry.category != nil
          tags.append(BHOF_CATTAG[app.entry.category])
        end

        # tag final pref --------------------------------------
        tags.append(BHOF_FINALTAG[app.final_decision])
        newact.user.tag(newact, tags)
        puts "#{newact.title} done as #{newact._id}"

        if not bhof_company.has_member?(newact.user)
          # add user to company with performer status
          cm = CompanyMembership.new
          cm.company = bhof_company
          cm.user = newact.user
          cm.access_level = 0

          # this should happen in-model and not here.
          cm.sort_name = cm.user.name.upcase
          cm.sort_username = cm.user.name.upcase
          cm.save

          puts "Added user #{cm.user.username} to company"
        end

      end
     }
  end

  task create_producer_invite: :environment do
    @u = User.where({ email: "jna@retina.net" })[0]
    @c = Company.find("552217766875623ded000000")

    @i = Invitation.new
    @i.single_use = false
    @i.sender = @u
    @i.access_level = 8
    @i.type = 0
    @i.company_id = @c._id.to_s
    @i.email = ""
    @i.valid_until = nil
    @i.used = false
    @i.generate_token
    puts @i.save
    puts @i.errors.full_messages

    puts "http://troupeit.com/invitation/" + @i.token + "/accept"
  end

  task set_eventcode: :environment do
    App.all.each { |a|
      a.event_code = "bhof_weekend_2015"
      a.save
    }
  end


  task fetch_members: :environment do
    Pluot.account_id = Rails.application.secrets.wa_account_id
    Pluot.api_key = Rails.application.secrets.wa_api_key

    # this takes some time,so we should cache it.
    c = Pluot.contacts.all
    File.open("/tmp/bhof-members.json", "w+") do |f|
      f.write JSON.pretty_generate(c)
    end

    # now ingest the file
    file = File.read("/tmp/bhof-members.json")

    data_hash = JSON.parse(file)

    BhofMember.all.destroy
    if data_hash["Contacts"].present? and data_hash["Contacts"].count > 0
      data_hash["Contacts"].each { |m|
        bm = BhofMember.new
        bm.first_name = m["FirstName"]
        bm.last_name = m["LastName"]
        bm.email = m["Email"]
        bm.wa_creation_date = m[""]
        bm.membership_status = m["Status"]
        bm.memberid = m["Id"]

        bm.renewal_due = HashFind.byname(m["FieldValues"], "FieldName", "Value", "Renewal due")
        bm.member_since = HashFind.byname(m["FieldValues"], "FieldName", "Value", "Member since")

        bm.save
      }
    else
     STDERR.puts "No records in response from wild apricot."
    end
  end

  # calculate how much we owe to BHOF
  task payout: :environment do
    total = 0
    discounted = 0
    standard = 0
    stripe = 0.0

    App.where(event_code: "bhof_weekend_2020").each { |a|
      if a.purchase_price.present? and a.stripe_customer_id.present?
        total = total + a.purchase_price

        if a.purchase_price == 2900
          discounted += 1
          fee = 1.14
          stripe = stripe + fee
        end

        if a.purchase_price == 3900
          standard += 1
          fee = 1.43
          stripe = stripe + fee
        end
      end
    }

    total = total * 0.01

    # our cut is 3.95 per app.
    cut = 3.95 # per app
    troupeit_fee = (discounted + standard) * cut


    puts "Discounted Total: #{discounted * 29.00}"
    puts "  Standard Total: #{standard * 39.00}"

    puts " Stripe fees: #{"%20s" % ActionController::Base.helpers.number_to_currency(stripe)}"
    puts "troupeIT Cut: #{"%20s" % ActionController::Base.helpers.number_to_currency(troupeit_fee)} ($3.95 * #{discounted + standard})"
    puts "troupeIT mem: #{"%20s" % ActionController::Base.helpers.number_to_currency(119.88)}"
    puts "     To BHOF: #{"%20s" % ActionController::Base.helpers.number_to_currency(total - stripe - troupeit_fee - 119.88)}"
    puts "              " + "-" * 20
    puts "       Total: #{"%20s" % ActionController::Base.helpers.number_to_currency(total)}"
    puts ""
    puts "@ $29.00: #{discounted}"
    puts "@ $39.00: #{standard}"
    puts "          #{discounted + standard} Total"
  end


  # calculate how much we owe to BHOF
  task export_apps: :environment do
    count = 0
    stripe = 0
    paypal = 0

    CSV.open("apps.csv", "wb") do | csv|
      App.where(event_code: "bhof_weekend_2020").each { |a|
        if a.stripe_customer_id.present?
          stripe = stripe + 1
        end

        if a.purchase_price.present?
          csv << a.attributes.values
          count = count + 1
        end

        if a.express_payer_id.present?
          paypal = paypal + 1
          #          puts a.to_json
        end
      }
    end

    puts "Total with purchase price = #{count}"
    puts "Stripe #{stripe}"
    puts "Paypal #{paypal}"
  end

  task remove_deadline: :environment do
    File.readlines("/home/jna/bhof_no_deadline.txt").each do |line|
      u = User.where({ email: line.strip })
      if u.count > 0
        r = Role.where({ name: "bhof_no_deadline" })
        if r.count > 0
          r[0].user << u
          r[0].save
        else
           puts "can't find role!"
        end
      else
        puts "couldn't find #{line.strip}!"
      end
    end
  end

  task test_final: :environment do
    @u = User.where({ email: "jna@retina.net" })[0]
    MarketingMailer.bhof_sendresult(@u).deliver
  end

  task notify_final: :environment do
    # You can use /tmp/skip_mails.txt to suppress sending of mails to users
    if File.file?("/tmp/skip_mails.txt")
      already_sent = IO.readlines("/tmp/skip_mails.txt").map(&:strip)
    else
      # empty array
      already_sent = Array.new
    end

    App.all_of({ event_code: "bhof_weekend_" + BHOF_YEAR, locked: true }).distinct(:user).each { |a|
      u = User.find(a)
      puts u.email
      begin
        if not already_sent.include?(u.email)
          puts "#{u.email} Sending mail"
          MarketingMailer.bhof_sendresult(u).deliver
        else
          puts "#{u.email} Already sent!"
        end
      rescue SparkPost::DeliveryException => e
        puts "SUPRESSED? #{u.email} #{e}"
      end
    }
  end

  task clear_verified: :environment do
    User.all.each { |u|
      u.bhof_member_id = nil
      u.save
    }
  end
end
