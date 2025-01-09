# config/initializers/public_activity.rb
PublicActivity::Config.set do
  orm :mongoid
end

module PublicActivity
  class Activity < inherit_orm("Activity")
  end
end