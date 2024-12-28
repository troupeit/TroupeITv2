module HashFind
  def self.byname(arr, namekey, valuekey, search)
    # return a valuekey in an array of hashes that
    # matches searchstring

    arr.each { |a|
      if a[namekey] == search
        return a[valuekey]
      end
    }

    nil
  end
end
