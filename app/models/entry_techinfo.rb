class EntryTechinfo
  include Mongoid::Document

  belongs_to :app

  field :created_at, type:  DateTime
  field :updated_at, type: DateTime

  field :song_title, type: String
  field :song_artist, type: String
  field :act_duration, type: String
  field :act_name, type: String
  field :act_description, type: String
  field :costume_Description, type: String
  field :costume_colors, type: String
  field :props, type: String
  field :other_tech_info, type: String
  field :setup_needs, type: String
  field :setup_time, type: String
  field :breakdown_needs, type: String
  field :breakdown_time, type: String
  field :sound_cue, type: String
  field :microphone_needs, type: String
  field :lighting_needs, type: String
  field :mc_intro, type: String
  field :aerial_needs, type: String
  field :additional_stage_needs, type: String

  def is_complete?
     if song_title.present? and
        song_artist.present? and
        act_duration.present? and
        act_name.present? and
        act_description.present? and
        costume_Description.present? and
        costume_colors.present? and
        props.present? and
        other_tech_info.present? and
        setup_needs.present? and
        setup_time.present? and
        breakdown_needs.present? and
        breakdown_time.present? and
        sound_cue.present? and
        microphone_needs.present? and
        lighting_needs.present? and
        mc_intro.present? and
        aerial_needs.present?
      true
     else
      false
     end
  end
end
