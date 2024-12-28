# This file contains a collection of mostly one-off, and sometimes not
# one-off fixes for tables associated with the site.
#
# Many of these tasks are extremely dangerous and will execute major
# database changes on all records. Because of database changes and
# evolution of the system, many of these functions might not even make
# sense. Use with extreme caution in production.

def make_thumbnail(source, target, width, height = nil)
  # convert an image into a thumbnail
  return nil unless File.file?(source)
  height ||= width

  begin
    img = Image.read(source).first
  rescue Magick::ImageMagickError
    return nil
    end

  rows, cols = img.rows, img.columns

  source_aspect = cols.to_f / rows
  target_aspect = width.to_f / height
  thumbnail_wider = target_aspect > source_aspect

  factor = thumbnail_wider ? width.to_f / cols : height.to_f / rows
  img.thumbnail!(factor)
  img.crop!(CenterGravity, width, height)

  img.write(target) { self.quality = 75 }
end

namespace :showmanager do
  include Magick

  task durfix: :environment do
    # convert old-style durations which were minute based to new style, which
    # are seconds based
    acts=Act.all
    acts.each { |a|
      a.length = a.length * 60
      a.save!
    }

    sis=ShowItem.find(:all)

    sis.each { |s|
      if s.duration > 0
        s.duration = s.duration * 60
        s.save!
      end
    }
  end

  task backfill_dates: :environment do
    ShowItem.all.each { |s|
     if s.act_id.present?
        begin
          a = Act.find(s.act_id)
          if a and s.show
            a.created_at = s.show.show_time
            a.updated_at = s.show.show_time

            s.created_at = s.show.show_time
            s.updated_at = s.show.show_time

            puts s.show.show_time

            puts a._id
            puts a.save
            puts s.save
          end
        rescue Mongoid::Errors::DocumentNotFound
           puts "cant find act #{s.act_id}"
        end
     end
    }
  end

  task replace_company_memberships: :environment do
    # DON'T RUN THIS UNTIL SECURITY WORKS.
    hubba_c = Company.where(name: /^Hubba/)[0]
    bhof_c = Company.where(name: /^Burlesque Hall of Fame$/i)[0]
    puts "Got Companies"

    CompanyMembership.where(company: hubba_c).destroy
    CompanyMembership.where(company: bhof_c).destroy
    puts "Cleared Companies"

    # hubba: If you've been in a show, you're good...
    ShowItem.all.each { |si|
      if si.act_id.present? and si.act_id != 0
        act = Act.where(id: si.act_id)[0]
        if act != nil
          # test for existence
          cmtest = CompanyMembership.where({ user: act.user, company: hubba_c })
          if cmtest != nil and cmtest.count > 0
            puts " would skip #{act.user.username.upcase}"
          else
            puts "add to company: #{act.user.username.upcase}"
            cm = CompanyMembership.new({ user: act.user, company: hubba_c, access_level: 0, sort_name: act.user.name.upcase, sort_username: act.user.username.upcase })
            cm.save
            puts "hubba: #{act.user.username.upcase}"
          end
        end
      end
    }

    App.all.each { |a|
      # bhof: If you were accepted, you're in ...
      if a.final_decision > 0
        cm = CompanyMembership.new({ user: a.user, company: bhof_c, access_level: 0, sort_name: a.user.name.upcase, sort_username: a.user.username.upcase })
        cm.save
        puts "bhof: #{a.user.username.upcase}"
      end
    }

    # take care of joyce and I
    u = User.where(name: /Comrade/)[0]
    cm = CompanyMembership.new({ user: u, company: bhof_c, access_level: 8, sort_name: u.name, sort_username: u.username.upcase })
    cm.save

    u = User.where(name: /Comrade/)[0]
    cm = CompanyMembership.new({ user: u, company: hubba_c, access_level: 8, sort_name: u.name, sort_username: u.username.upcase })
    cm.save

    u = User.where(name: /john adams/i)[0]
    cm = CompanyMembership.new({ user: u, company: bhof_c, access_level: 8, sort_name: u.name, sort_username: u.username.upcase })
    cm.save

    u = User.where(name: /john adams/i)[0]
    cm = CompanyMembership.new({ user: u, company: hubba_c, access_level: 8, sort_name: u.name, sort_username: u.username.upcase })
    cm.save
  end

  task redo_asset_metadata: :environment do
    @passets = Passet.all

    @passets.each do |p|
      @file = "#{UPLOADS_DIR}/#{p.uuid}"

      mime_type = IO.popen([ "file", "--brief", "--mime-type", @file ], in: :close, err: :close).read.chomp

      puts "#{@file} - #{mime_type}"
      p.kind=mime_type
      size = File.stat(@file).size
      p.asset_bytesize = size

      if mime_type.start_with?("image/")
        img = Magick::Image.read(@file).first
        width = img.columns
        height = img.rows
        puts "#{@file} #{width} x #{height}"

        p.img_size_x = width
        p.img_size_y = height
      end

      # we'll try to guess if they send us a binary...
      if mime_type.start_with?("audio/") or mime_type.start_with?("application/octet-strean")
        title = TagLib::MPEG::File.open(@file) do |file|
          tag = file.tag
          prop = file.audio_properties

          p.song_artist = tag.artist
          p.song_title = tag.title
          p.song_length = prop.length
          p.song_bitrate = prop.bitrate

    if p.song_length == 0
            # failed, try exiftool instead?
            m = MiniExiftool.new @file

            # fix duration
            if not m.duration.nil?
              parts = m.duration.split(":")
              t = (parts[0].to_i * 3600) + (parts[1].to_i * 60) + parts[1].to_i
              p.song_length = t
              puts t
            end

            # fix bitrate
            if not m.bitrate.nil?
              p.song_bitrate = m.bitrate.gsub(/ *kbps/i, "")
            elsif not m.avg_bitrate.nil?
              p.song_bitrate = m.avg_bitrate.gsub(/ *kbps/i, "")
            end

            puts p.song_bitrate

            # fix artist
            if p.song_artist == ""
              puts "fixed artist: #{m.artist}"
              p.song_artist = m.artist
            end

            # fix song title
            if p.song_title == ""
              puts "fixed title: #{m.title}"
              p.song_title = m.title
            end
    end
        end
      end

      p.save
    end
  end

  task tzfix: :environment do
    PublicActivity.enabled = false

    events = Event.all

    events.each { |e|
      puts e.title
      puts e.time_zone
      puts "---"
      e.time_zone  = "America/Los_Angeles"
      e.save!
    }
  end

  task reset_trials: :environment do
    PublicActivity.enabled = false
    t = Time.now + (86400 * 30)
    users = User.all
    users.each { |u|
      u.trial_expires_at = t
      puts u.email
      begin
        u.save!
      rescue Mongoid::Errors::Validations
        puts "can't update user #{u._id} #{u.username} - invalid validation"
      end
    }
  end

  task attach_assets: :environment do
    PublicActivity.enabled = false

    Act.all.each { |a|
      ActAsset.where(act: a).destroy

      if a.music.present? and a.music != "0"
       begin
        p = Passet.find(a.music)
        puts p

        as = ActAsset.new(act: a, seq: 1)
        as.passet = p
        as.save

       rescue Mongoid::Errors::DocumentNotFound
         puts "#{a.id} failed to find #{a.music}"
       end
      end

      if a.image.present? and a.image != "0"
       begin
        p = Passet.find(a.image)
        puts p

        as = ActAsset.new(act: a, seq: 2)
        as.passet = p
        as.save
       rescue Mongoid::Errors::DocumentNotFound
          puts "#{a.id} failed to find #{a.image}"
        end
      end

      a.save
    }
  end

  task repair_created_at: :environment do
    u = User.all

    u.each { |u|
      puts "#{u._id} #{u.created_at}"

      if u.created_at.blank?

        if not u.trial_expires_at.nil?
          u.created_at = u.trial_expires_at - 30.days
          u.save
        else
          # try to recover via firt bhof app
          if u.apps.count > 0
            u.created_at = u.apps.first.created_at
            u.save
          else
            # try to recover via first act
            if u.acts.count > 0
              u.created_at = u.acts.first.created_at
              u.save
            else
              # give up, use last sign in, because this person hasn't built anything.
              if u.last_sign_in_at.nil?
                puts "last try exhausted"
              else
                u.created_at = u.last_sign_in_at
                u.save
              end
            end
          end
        end
      end
    }

    puts "nil"
    puts User.where({ created_at: nil }).count

    puts "not nil"
    puts User.where({ :created_at.ne => nil }).count
  end


  task recover_creation_dates: :environment do
    text = File.open("#{Rails.root}/log/creations.log").read
    text.each_line do |line|
      parts = line.split("|")
      users = User.where({ email: parts[0] })
      if users.count > 0
        u = users[0]
        if u.created_at.nil?
          u.created_at = parts[1]
          u.save
        end
      end
    end
  end

  task migrate_to_s3: :environment do
    # note that AWS environemnt must be set before this will work.

    Passet.all.each { |p|
      s3 = Aws::S3::Resource.new(region: ENV["AWS_REGION"])
      destkey = "uploads/" + p.uuid + File.extname(p.filename)
      puts "put: #{destkey}"
      begin
        obj = s3.bucket("troupeit-uploads").object(destkey)

        # upload the main file
        obj.upload_file("/retina/hubba/showmanager-data/uploads/#{p.uuid}",
          {
           content_type: p.kind,
           acl: "public-read"
          })

        # deal with images if any...
        if p.kind.match(/^image/)
          # we'll make three sizes here because we can, and we have time
          [ 100, 200, 400 ].each { |ts|
            # since we know our filenames are always uuid.ext, this gsub
            # should be fine.
            thumbfile = p.uuid + ".thumb-#{ts}x#{ts}" + File.extname(p.filename)
            tempfile="/tmp/#{thumbfile}"
            result = make_thumbnail("/retina/hubba/showmanager-data/uploads/#{p.uuid}",
                                    tempfile, ts, ts)

            if result.nil?
               STDERR.puts "Error making thumbnail - abort."
            end
            destkey="thumbs/#{thumbfile}"
            obj = s3.bucket("troupeit-uploads").object(destkey)
            puts "thumb: " + tempfile
          obj.upload_file(tempfile,
                            {
                              content_type: p.kind,
                              acl: "public-read"
                            })

            File.delete(tempfile)
          }
        end
      rescue
        puts "bad file? Skipping."
      end
    }
  end

  task fix_s3_perms: :environment do
    # make everything in the bucket public-read.
    s3 = Aws::S3::Resource.new(region: Rails.application.credentials.aws_sqs_region,
                               access_key_id: Rails.application.credentials.aws_access_key,
                               secret_access_key: Rails.application.credentials.aws_secret_key)
    bucket = s3.bucket("troupeit-uploads")
    bucket.objects.each do |obj|
      puts obj.key
      obj.object.acl.put({ acl: "public-read" })
    end
  end
end
