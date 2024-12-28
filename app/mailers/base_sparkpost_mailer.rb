require "sparkpost"

class BaseSparkpostMailer < ActionMailer::Base
  @@host = "https://api.sparkpost.com"

  default(
    from: "TroupeIT <do-not-reply@troupeit.com>",
    reply_to: "do-not-reply@troupeit.com"
  )

  private

  def send_mail(email, subject, body)
    SparkPost::Request.request("#{@@host}/api/v1/transmissions",
                               Rails.application.config.action_mailer.smtp_settings[:password],
                               {
                                 recipients: [
                                   {
                                     address: { email: email }
                                   }
                                 ],
                                 content: {
                                   subject: subject,
                                   template_id: "default-one-coa"
                                 },
                                 substitution_data: {
                                   body: body
                                 }
                               })
  end

  def send_template(email, subject, template_name, attributes)
    SparkPost::Request.request("#{@@host}/api/v1/transmissions",
                               Rails.application.config.action_mailer.smtp_settings[:password],
                               {
                                 recipients: [
                                   {
                                     address: { email: email }
                                   }
                                 ],
                                 content: {
                                   subject: subject,
                                   template_id: template_name
                                 },
                                 substitution_data: attributes
                               })
  end
end
