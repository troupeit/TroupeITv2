class Passet
  # individual assets assigned to a user
  include Mongoid::Document
  include Mongoid::Timestamps
  include TimeTools
  include ActionView::Helpers::DateHelper
  include PublicActivity::Model

  tracked except: [ :update ],
          owner: Proc.new { |controller, model| controller.current_user },
          params:  {
            title: proc { |controller, model| (model.filename) }
          }

  belongs_to :user
  belongs_to :act_asset

  # field :created_at, type:  DateTime
  field :created_by, type:  String

   field :uuid, type:  String
   field :filename, type:  String
   field :kind, type:  String
   field :notes, type:  String

   # these fields are available if tagging has suceeded
   field :song_artist, type:  String
   field :song_title, type:  String
   field :song_length, type:  Integer
   field :song_bitrate, type:  Integer

   field :asset_bytesize, type:  Integer

   field :img_size_x, type:  Integer
   field :img_size_y, type:  Integer

   # sndchecker quality store
   field :sound_quality_score, type:  Float

   field :processed, type:  Integer, default: 1

   before_destroy { |record| ActAsset.destroy_all(passet: record.id) }

   # You can leave +height+ blank if you like.
   def thumb_path(w, h = nil)
     h ||= width / aspect_ratio
     "#{uuid}-#{w.to_i}x#{h.to_i}.jpg"
   end

   # Where to store images in the filesystem when they
   # are created.
   def image_path(w, h = nil)
     "#{THUMBS_DIR}/#{thumb_path(w, h)}"
   end

   # Generate thumbnail from the original image
   def thumbnail!(w, h)
     logger.debug("#{UPLOADS_DIR}/#{uuid} ---> #{image_path(w,h)} thumbnail create")
     ImageTools.thumbnail("#{UPLOADS_DIR}/#{uuid}", image_path(w,h), w.to_i, h.to_i)
   end

   def icon
     if self.kind.starts_with?("audio/")
       "/sa/images/audio.png"
     else
       "/s/#{self.thumb_path(100,100)}"
     end
   end

   def is_image?
     self.kind.starts_with?("image/")
   end

   def is_audio?
     self.kind.starts_with?("audio/")
   end

   def is_video?
     self.kind.starts_with?("video/")
   end

   def to_html
     # return a textual description of this asset for use on many pages.
     # I don't like conflicting the view and the model here but this seems sensible.
     out = self.filename + "<BR>"
     if self.song_artist != nil
       out = out + self.song_artist + " - "
     end
     
     if self.song_title != nil
       out = out + self.song_title + " <BR> "
     end
     
     out = out + "<div class=\"greyed\">"
     out = out + self.kind
     
     if self.is_audio? and self.song_length.present?
       if self.song_length > 0
         out = out + ", " + TimeTools.sec_to_mmss(self.song_length) + " long, " + self.song_bitrate.to_s + " Kbit bitrate<BR>"
       end
     end
     
     out = out + "</div>" + self.created_at.asctime + " "


     out = out + "<I> (" + time_ago_in_words(self.created_at) + " ago)</I>"
     if self.asset_bytesize.present?
       #       out = out + "<BR>" + number_with_delimiter(self.asset_bytesize, :delimiter => ',') + " bytes"
              out = out + "<BR> #{self.asset_bytesize}"
     end
     out
   end

   def post_process!
     # should this be global instead of local here?
     client = Aws::SQS::Client.new( :access_key_id => Rails.application.secrets.aws_access_key,
                                    :secret_access_key => Rails.application.secrets.aws_secret_key,
                                    :region => Rails.application.secrets.aws_sqs_region )

     client.send_message({ queue_url: Rails.application.secrets.aws_sqs_baseurl + "upload_processing",
                           message_body: self.to_json });
   end
   
end
