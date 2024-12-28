# coding: utf-8

# mailer for transactional mails via Mandrill
class MarketingMailer < BaseSparkpostMailer
  def bhof_sendresult(record)
    merge_vars = {
      "TITLE" => "BHOF #{BHOF_YEAR} Application results now available!",
      "SUBJECT" => "BHOF #{BHOF_YEAR} Application results now available!",
      "YEAR" => Time.now.year,
      "HEADLINE" => "Results now available",
      "SUBHEADLINE" => "Hello, #{record.first_name}! Thanks for applying!",
      "BODY" => "Judging has completed for the BHOF #{BHOF_YEAR} Weekender.",
      "TOPIMG" => { "url" => "https://bhofweekend.com/wp-content/uploads/2016/01/bhoflogo.png",
                   "width" =>  224,
                   "height" => 100 },
      "CTA" => "See your results",
      "CTALINK" => "https://troupeit.com/apps"
    }

    send_template(record.email, merge_vars[:SUBJECT], "bhof-msg", merge_vars)
  end
end
