module DecidersHelper
  def DECIDER(key)
     # returns a decider value based on the environment.
     # Deciders that are not available return 0.0
     res = Decider.where({ key: key })[0]
     if res.present?
       val = res.value_f

       case Rails.env
       when "test"
           val = res.value_f_test
       when "development"
           val = res.value_f_staging
       when "production"
           val = res.value_f
       end
     else
       logger.debug("DECIDER: Warning, decider key #{key} not found.")
       val = 0.0
     end

     val
  end
end
