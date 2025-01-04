require 'net/http'
require 'erb'
require 'json'

module JoinIt
  class << self
    # write a method that takes in an email address and calls the joinIT API to get the user's information
    # if the user is not found, return nil
    # if the user is found, return a hash with the user's information
    ACCEPTABLE_STATUS = [75, 100]
    def get_user(email) 
      # get the user's information from the joinIT API
      url = URI("https://app.joinitapi.com/api/v1/organizations/me/memberships\?email=#{ ERB::Util.url_encode(email)  }")
      req = Net::HTTP::Get.new(url)
      # security: hardcoding this for now.
      req['authorization'] = "Bearer jDKQip9oYG57Ac25P"
      req['accept'] = "application/json"

      res = Net::HTTP.start(url.hostname, url.port, use_ssl: url.scheme == 'https') { |http|
        http.request(req)
      }
      
      # abort if we don't get a 200 response
      if (res.code.to_i != 200) 
        return nil
      end

      # have member, parse it. 
      member = JSON.parse(res.body)
      return member
    end

    def is_valid(member) 
      if (!member) 
        return nil
      end
      if (member.count == 0)
        return nil
      end
      ACCEPTABLE_STATUS.include?(member[0]["status"])
    end
  end
end


# tests
# invalid member
#m = JoinIt.get_user("lucyfurrproductions@gmail.com")
#puts m
#puts JoinIt.is_valid(m)

# valid member
#m = JoinIt.get_user("mcp_melim@live.com")
#puts m
#puts JoinIt.is_valid(m)
