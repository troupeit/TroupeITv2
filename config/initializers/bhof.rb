Rails.configuration.after_initialize do
  # constants, which we will move to a db at some point for the BHOF application
  ::BHOF_YEAR = "2025"
  ::BHOF_TITLE = "BHoF Weekender #{BHOF_YEAR}"
  ::BHOF_WEEKEND_DATES = "June 5th, 2025 to June 8th, 2025"
  ::BHOF_EMAIL = "applications@bhofweekend.com"

  # we'll use this event code in all new acts
  ::BHOF_EVENTCODE = "bhof_weekend_2025"

  # all of these dates need updating!!!
  ::BHOF_DISCOUNT_DEADLINE = DateTime.new(2024, 12, 27, 23, 59, 59, "-08:00")
  ::BHOF_FINAL_DEADLINE    = DateTime.new(2025, 1, 25, 23, 59, 59, "-08:00")

  # Need this from dustin
  ::BHOF_RSVP_DEADLINE     = DateTime.new(2025, 4, 1, 23, 59, 59, "-08:00") # TBD

  # application rates, in cents. If the current date is after the deadline, the new rates applies
  ::BHOF_RATES = [ { deadline: DateTime.new(2000, 1, 1, 0, 0, 00, "-08:00"), rate: 2900 },
                   { deadline: BHOF_DISCOUNT_DEADLINE, rate: 3900 } ]

  # and this money goes to TroupeIT...
  ::BHOF_SERVICE_CHARGE = 395

  if Rails.env == "development"
    ::BHOF_HOST = "dev.troupeit.com"
    ::BHOF_URL  = "https://#{BHOF_HOST}"
  else
    ::BHOF_HOST = "troupeit.com"
    ::BHOF_URL  = "https://#{BHOF_HOST}"
  end

  # Initialize the round, if necessary
  bhof_round = Decider.where(key: "bhof_round")

  if bhof_round.length == 0
    Decider.create({ "key" => "bhof_round", "value_f" => 1 })
  end
end
