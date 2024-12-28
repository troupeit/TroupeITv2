class EventSubmission
  include Mongoid::Document
  include Mongoid::Timestamps
  include PublicActivity::Model

  tracked except: [ :update ],
           owner: Proc.new { |controller, model| controller.current_user },
           params: {
             act_id: proc { |controller, model| (model.act_id) },
             event_id: proc { |controller, model| (model.event_id) },
             act_stage_name: proc { |controller, model| (model.act.stage_name) },
             event_title: proc { |controller, model| (model.event.title) }
           }

  belongs_to :event
  belongs_to :act
  belongs_to :user

  index({ act_id: 1, event_id: 1 }, { unique: true })

  field :accepted, type:  Boolean, default: alse
  field :is_alternate, type:  Boolean, default:  false
end
