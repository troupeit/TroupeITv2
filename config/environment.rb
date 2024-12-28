# Load the Rails application.
require_relative "application"

if Rails.env == "production"
  UPLOADS_DIR = "/retina/hubba/showmanager-data/uploads"
  THUMBS_DIR = "#{UPLOADS_DIR}/thumbs"
else
  UPLOADS_DIR = "#{Rails.root}/uploads"
  THUMBS_DIR = "#{UPLOADS_DIR}/thumbs"
end

# our shortened time format
# Sun Jan 1, 2012 5:00 PM
# we're assuming an english-us locale ho well!
SHORT_TIME_FMT = "%a %b %d, %Y %I:%M %p"
SHORT_TIME_FMT_TZ = "%a %b %d, %Y %I:%M %p %Z"
SHORT_DATE_FMT = "%a %b %d, %Y"

LONG_DATE_FMT = "%A, %B %e, %Y at %I:%M %p"
LONG_DATE_FMT_TZ = "%A, %B %e, %Y at %I:%M %p %Z"

TIME_ONLY_FMT = "%l:%M %p"
TIME_ONLY_FMT_TZ = "%l:%M %p %Z"

# FB Integration
FACEBOOK_APP_ID = "308336679243664"

# Initialize the Rails application.
Rails.application.initialize!
