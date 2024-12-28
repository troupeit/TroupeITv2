class Ability
  include CanCan::Ability
  # This class controls CanCan
  #
  # The first argument to `can` is the action you are giving the user permission to do.
  # If you pass :manage it will apply to every action. Other common actions here are
  # :read, :create, :update and :destroy.
  #
  # The second argument is the resource the user can perform the action on. If you pass
  # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
  #
  # The third argument is an optional hash of conditions to further filter the objects.
  # For example, here the user can only update published articles.
  #
  #   can :update, Article, :published => true
  #
  # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    @user = user  || User.new # guest user (not logged in)

    if user.has_role? :admin
      can :manage, :all
    end

    if user.has_role? :stage_manager
      can :manage, Act
      can :manage, Passet
      can :manage, Role
      can :manage, Show
      can :manage, ShowItem
      can :manage, Troupe
      # can :manage, User
    end

    if user.has_role? :crew
      can :read, Act
      can :create, Act
      can :manage, Act, :user_id => user.id

      can :read, Passet
      can :manage, Passet, :user_id => user.id

      # read-only for system properties
      can :read, Role
      can :read, Show
      can :read, ShowItem
      can :read, Troupe

      can :manage, User, :id => user.id
    end

  end
end
