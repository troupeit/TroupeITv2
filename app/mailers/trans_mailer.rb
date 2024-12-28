# coding: utf-8

# mailer for transactional mails via Mandrill
class TransMailer < BaseSparkpostMailer
  def generic(user, subject, title, subtitle, intro, message)
    # a generic message based on a simple template
    merge_vars = {
      "YEAR" => Time.now.year,
      "TITLE" => title,
      "HEADLINE" => title,
      "SUBHEADLINE" => subtitle,
      "INTRO" => intro,
      "BODY" => message
    }
    send_template(user.email, subject, "default-one-coa", merge_vars)
  end

  # devise methods

  def confirmation_instructions(record, token, opts = {})
    # code to be added here later
  end

  def reset_password_instructions(record, token, opts = {})
    merge_vars = {
      "YEAR" => Time.now.year,
      "TITLE" => "Password Reset",
      "SUBJECT" => "troupeIT Password Reset",
      "HEADLINE" => "Reset your password",
      "SUBHEADLINE" => "Hello, #{record.first_name}!",
      "CTA" => "Reset Password",
      "CTALINK" => "https://www.troupeit.com/users/password/edit?reset_password_token=#{token}",
      "BODY" => "It's okay, we all forget sometimes!",
      "BODY2" => "To reset your password, click the button below or open the following link",
      "BODY3" => "https://www.troupeit.com/users/password/edit?reset_password_token=#{token}",
      "BODY4" => "If you did not request this mail, you can safely ignore it."
    }

    send_template(record.email, merge_vars[:SUBJECT], "default-one-coa", merge_vars)
  end

  def unlock_instructions(record, token, opts = {})
    # code to be added here later
  end

  def post_welcome(record)
    merge_vars = {
      "YEAR" => Time.now.year,
      "TITLE" => "Just checking in.",
      "SUBJECT" => "Just checking in.",
      "HEADLINE" => "Welcome! How's it going?",
      "SUBHEADLINE" => "Hello, #{record.first_name}!",
      "CTA" => "Log into troupeIT",
      "CTALINK" => "https://www.troupeit.com",
      "BODY" => "Hey there. Thanks for signing up for troupeIT.",
      "BODY2" => "We want to make sure that you were enjoying your free, 30-day producer trial.<BR><BR>If you're a performer, tell your stage manager or organizer about troupeIT. We make running shows simpler and reduce mistakes by giving you the tools you need to run a great show.<BR>",
      "BODY3" => "We've spent a long time trying to make shows easier for people just like you and we're thrilled to share troupeIT with you for your events <BR><BR>If you have any questions about the product, feedback, or need help, just drop us a note. We're always here to help."
    }

    send_template(record.email, merge_vars[:SUBJECT], "default-one-coa", merge_vars)
  end

  def trial_expires_soon(record)
    merge_vars = {
      "YEAR" => Time.now.year,
      "TITLE" => "Trial expires soon",
      "SUBJECT" => "Trial expires soon",
      "HEADLINE" => "Don't be left out!",
      "SUBHEADLINE" => "Hello, #{record.first_name}!",
      "CTA" => "Subscribe Now",
      "CTALINK" => "https://troupeit.com/companies/",
      "BODY" => "Your <strong>producer</strong> trial ends in just a few days.",
      "BODY2" => "Why go back to spreadsheets, broken files, and piles of CDs?<br>Put your show on <strong>troupeIT!</strong>",
      "BODY3" => "As a producer, you can create companies, events, and shows with your crew.<br>",
      "BODY4" => "<strong>If you're a Performer in an existing show, don't panic!</strong><br> You can continue to submit acts to events for free without being a producer.<br> <br> But, if you manage a stage of your own, pick a billing plan now to keep your membership going.<BR><BR>Our plans start at <strong>$19.99/month</strong>, and are as low as <strong>$9.99/month </strong>when you buy six months in advance.<br>",
      "TOPIMG" => { url: "https://www.filepicker.io/api/file/Fw5bWPbwRkG3N9o2zwB0",
                    width: 253,
                    height: 181 }
    }

    send_template(record.email, merge_vars[:SUBJECT], "default-one-coa-nontrx", merge_vars)
  end

  def trial_expired(record)
    merge_vars = {
      "YEAR" => Time.now.year,
      "TITLE" => "Your producer trial has ended",
      "SUBJECT" => "Your producer trial has ended",
      "HEADLINE" => "Oh no! Your trial has ended.",
      "SUBHEADLINE" => "Hello, #{record.first_name}!",
      "CTA" => "Subscribe Now",
      "CTALINK" => "https://troupeit.com/companies/",
      "BODY" => "We hate to see you go. Continue to use all of the features of the easiest stage management tool now with a low-cost subscription.",
      "BODY2" => "<strong>If you're a Performer in an existing show, don't panic!</strong><br> You can continue to submit acts to events for free without being a producer.<br> <br> If you manage a stage of your own, pick a billing plan <b>now</b> to manage your shows and crew.<BR><BR>Our plans start at <strong>$19.99/month</strong>, and are as low as <strong>$9.99/month </strong>when you buy six months in advance.<br>",
      "TOPIMG" => { url: "https://www.filepicker.io/api/file/Fw5bWPbwRkG3N9o2zwB0",
                    width: 253,
                    height: 181 }
    }

    # give them a second chance
    # I don't like having the mailer execute this sort of logic but unsure where else to put it!
    if record.trial_extended == false
      resetkey = generate_reset(record)

      merge_vars["BODY3"]  = "<strong>Need more time?</strong> We know, humans get busy. If you need more time, just <a href='https://troupeit.com/settings/extend_trial?t=#{resetkey.token}'>click here</a> and we'll give you another 30 days to experience troupeIT (but, you can only extend once!)"
    end

    send_template(record.email, merge_vars[:SUBJECT], "default-one-coa-nontrx", merge_vars)
  end

  def resurrect(record)
    merge_vars = {
      "YEAR" => Time.now.year,
      "TITLE" => "We Miss You.",
      "SUBJECT" => "We Miss You!",
      "HEADLINE" => "We Miss You!",
      "SUBHEADLINE" => "Hello, #{record.first_name}. It's been awhile!",
      "CTA" => "Try us again",
      "CTALINK" => "https://troupeit.com/companies/",
      "BODY" => "You previously signed up up for troupeIT and I think you should check us out again.",
      "BODY2" => "troupeIT is one of the easiest to use show management systems and I'd like to welcome you back with an additional,<br><b>free, 30-day trial</b>.",
      "BODY3" => "Don't know where to begin? I’m the founder of this company, and I love talking to customers, about either our product or your needs. Reply to this email and I will get back to you, within a day.",
      "BODY4" => "John Adams, Founder.",
      "TOPIMG" => { url: "https://www.filepicker.io/api/file/Fw5bWPbwRkG3N9o2zwB0",
                    width: 253,
                    height: 181 }
    }

    if record.trial_extended == false
      resetkey = generate_reset(record)
      merge_vars["BODY3"] =  "Don't know where to begin? I’m the founder of this company, and I love talking to customers, about either our product or your needs. Reply to this email and I will get back to you, within a day.  I'll even give you another 30-day trial if you  <a href='https://troupeit.com/settings/extend_trial?t=#{resetkey.token}'>click this link.</a>"
    end
    send_template(record.email, merge_vars[:SUBJECT], "default-one-coa-nontrx", merge_vars)
  end

  private

  def generate_reset(user)
    # geneate a resetkey for a specific user
    # used in marketing mails / resurrections usually
    resetkey = Resetkey.new
    resetkey.user = user
    resetkey.generate_token!
    resetkey.save

    user.trial_extended = true
    user.save

    resetkey
  end
end
