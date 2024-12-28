# app/controllers/passwords_controller.rb
class PasswordsController < Devise::PasswordsController
  # Overrides to require a user to log in after resetting the password

  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message(:notice, flash_message) if is_flashing_format?

      # Do not automatically login if two-factor is enabled for this user.
      # Remove the following three lines entirely if you want to disable
      # automatic login for all users regardless, after a password reset.
      unless resource.try(:otp_required_for_login?)
        sign_in(resource_name, resource)
      end

      respond_with resource, location: after_resetting_password_path_for(resource)
    else
      respond_with resource
    end
  end

  protected

  def after_resetting_password_path_for(resource)
    new_session_path(resource)
  end

  def after_sending_reset_password_instructions_path_for(resource_name)
    set_flash_message(:notice, "send_instructions")
    "/users/sign_in"
  end
end
