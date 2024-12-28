module FileTools
  class << self
    def sanitize_filename(file_name)
      # get only the filename, not the whole path (from IE)
      just_filename = File.basename(file_name)
      # replace all none alphanumeric, underscore or perioids
      # with underscore
      just_filename.gsub(/[^[0-9a-zA-Z\.\-]]/, "_").gsub(/_+/, "_")
    end

    def sanitize_csv_filename(filename)
      # Split the name when finding a period which is preceded by some
      # character, and is followed by some character other than a period,
      # if there is no following period that is followed by something
      # other than a period (yeah, confusing, I know)
      fn = filename.split /(?<=.)\.(?=[^.])(?!.*\.[^.])/m

      # We now have one or two parts (depending on whether we could find
      # a suitable period). For each of these parts, replace any unwanted
      # sequence of characters with an underscore
      fn.map! { |s| s.gsub /[^a-z0-9\-]+/i, "_" }

      # Finally, join the parts with a period and return the result
      fn.join "."
    end
  end
end
