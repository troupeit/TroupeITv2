class UserMailer < ActionMailer::Base
  default from: "do-not-reply@troupeit.com"
  layout "mailer-transactional"

  def bhof_results(app)
      @user = app.user
      @microtitle = "BHOF <%=::BHOF_YEAR %> results now available!"
      @title = "BHOF <%=::BHOF_YEAR %> Results"
      @message = "Results for BHOF <%=::BHOF_YEAR %> have been posted. To view them, go to .... "
      mail(to: invitation.email, subject: "BHOF <%=::BHOF_YEAR %> Final Results")
  end
end
