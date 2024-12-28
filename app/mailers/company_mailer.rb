class CompanyMailer < ActionMailer::Base
  default from: "do-not-reply@troupeit.com"
  layout "mailer-transactional"

  def invitation(user, invitation, company)
      @user = user
      @invitation = invitation
      @company = company

      @invite_url = "#{BHOF_URL}/invitation/" + @invitation.token + "/accept"
      @microtitle = "Invitation from #{user.name}"
      @title = "Invite: #{company.name.titleize}"
      @message = "#{user.name} has invited you to join the company \"#{company.name}\". To accept, just click the button below."
      @joinbuttons = false

      mail(to: invitation.email, subject: "companyIT: \"#{company.name}\" invitation from #{user.name}")
      invitation.update_attribute(:sent_at, Time.now)
  end
end
