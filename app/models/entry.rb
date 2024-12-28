class Entry
  include Mongoid::Document

  belongs_to :app

  include Mongoid::Timestamps

  field :name, type: String

  field :type, type: Integer  # 1 if solo, 2 if group(2015)/small group(2016), 3=large group(2016)
  field :num_performers, type: Integer    # "1" if a solo act
  field :all_performer_names, type: String

  field :city_from, type: String
  field :country_from, type: String
  field :performer_url, type: String
  field :video_url, type: String
  field :category, type: Integer  # 1=main, 2=debut, 3=boylesque

  field :compete_preference, type: Integer # 1=Compete only, 2=showcase only, or 3=either

  field :years_applied, type: String
  field :years_performed, type: String
  field :other_stage_names, type: String

  field :years_experience, type: String
  field :style, type: String
  field :why_act_unique, type: String
  field :outside_work, type: String
  field :comments, type: String

  field :video_notes, type: String

  def is_part1_complete?
   if self.type.nil?
     return false
   end

   # if it's a group, these two need to be filled out.
   if self.type >= 2 and (! self.num_performers.present? or ! self.all_performer_names.present?)
     return false
   end

   # we only care about this if we're type 1
   if self.type == 1 and ! self.category.present?
     return false
   end

   if self.type.present? and
      self.city_from.present? and
      self.country_from.present? and
      self.performer_url.present? and
      self.video_url.present? and
      self.compete_preference.present? and
      self.years_applied.present? and
      self.years_performed.present? and
      self.other_stage_names.present?
      true
   else
      false
   end
  end

  def is_part2_complete?
    if self.comments.present? and
       self.video_notes.present?
      true
    else
      false
    end
  end

  def is_complete?
     self.is_part1_complete? && self.is_part2_complete?
  end
end
