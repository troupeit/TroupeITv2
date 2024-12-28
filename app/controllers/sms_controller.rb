class SmsController < ApplicationController
  # this class handles inbound sms messages, for example, the 'stop' message.
  def voice
    # TWXML voice handler
  end

  def inbound
    # this endpoint only responds in XML
    if params[:Body].downcase.include?("stop")

      # strip US country code
      cleanedph = params[:From].gsub(/^\+1/, "")

      u = User.where({ phone_number: cleanedph })
      if u.count > 0
        u[0].sms_notifications = false
        u[0].save
        @message = "Okay. SMS notifications for your phone are now disabled. Return to https://troupeit.com/settings/edit to re-enable."
      else
        @message = "We couldn't find your phone number. Please go to https://troupeit.com/settings/edit to disable SMS notifications."
      end
    else
      @message = "Hi! You've replied to the troupeIT robot. Reply STOP to turn off SMS notifications. Msg & Data rates may apply. https://troupeit.com"
    end
  end
end
