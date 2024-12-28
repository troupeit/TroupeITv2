module TimeTools
    def self.sec_to_time(n)
      if n == nil
        return "00:00:00"
      end

      (Time.mktime(0) + n).strftime("%H:%M:%S")
    end

    def self.sec_to_mmss(n)
      if n == nil
        return "00:00"
      end

      (Time.mktime(0) + n).strftime("%M:%S")
  end
end
