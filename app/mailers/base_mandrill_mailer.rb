# app/mailers/base_mandrill_mailer.rb

require "mandrill"

class BaseMandrillMailer < ActionMailer::Base
  default(
    from: "do-not-reply@troupeit.com",
    reply_to: "do-not-reply@troupeit.com"
  )

  private

  def send_mail(email, subject, body)
    mail(to: email, subject: subject, body: body, content_type: "text/html")
  end

  def mandrill_template(template_name, attributes)
    mandrill = Mandrill::API.new(Rails.application.config.action_mailer.smtp_settings[:password])

    merge_vars = attributes.map do |key, value|
      { name: key, content: value }
    end

    mandrill.templates.render(template_name, [], merge_vars)["html"]
  end
end
