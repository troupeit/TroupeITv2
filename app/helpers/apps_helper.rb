module AppsHelper
  ::NR_STRINGS  = { -1 => "Undecided",
                     1 => "Yes",
                     2 => "Maybe",
                     0 => "No" }


  ::RSVP_STRINGS  = { -1 => "Undecided",
                       1 => "Accepted",
                       0 => "Declined" }

  ::BHOF_CATS = [ "",
                  "M. EW (Has Performed)",
                  "Debut (Has Never Performed)",
                  "Group"
                ]

  ::BHOF_MEW_TITLES = [
    "",
    "Ms. Exotic World",
    "Mrs. Exotic World",
    "Mr. Exotic World",
    "Mx. Exotic World",
    "Other"
  ]

  ::BHOF_SELECT_HASH = {
      "All" => 0,
      "M. EW (Has Performed)" => 1,
      "Debut (Has Never Performed)" => 2,
      "Group" => 3
  }

  ::BHOF_COMP_PREF = [ "", "All Shows", "Tournament Only", "Showcase Only" ]

  ::BHOF_TYPES = [ "", "Solo", "Group" ]

  ::BHOF_FINAL_DECISION = { 0 => "Out",
                            1 => "Saturday (competition) - Boylesque",
                            2 => "Saturday (competition) - Large Group",
                            3 => "Saturday (competition) - Small Group",
                            4 => "Saturday (competition) - Debut",
                            5 => "Saturday (competition) - MEW/Reigning Queen",
                            6 => "Thursday (MSI Showcase)",
                            7 => "Thursday + Saturday Alternate",
                            8 => "Saturday Alt Only",
                            9 => "Thursday Alt Only",
                            10 => "Friday"
                          }


  ::BHOF_FINAL_FILEMAP = { 0 => "2024_out",
                           1 => "2024_in_for_saturday_boylesque",
                           2 => "2024_in_for_saturday_large_group",
                           3 => "2024_in_for_saturday_small_group",
                           4 => "2024_in_for_saturday_debut",
                           5 => "2024_in_for_saturday_mew",
                           6 => "2024_in_for_thursday",
                           7 => "2024_in_for_thursday_alternate_for_saturday",
                           8 => "2024_saturday_alternate",
                           9 => "2024_thursday_alternate",
                           10 => "2024_in_for_friday"
                         }

  def type_to_s(type)
    BHOF_TYPES[type]
  end

  def compete_to_s(compete)
    BHOF_COMP_PREF[compete]
  end

  def cat_to_s(category)
    # TODO: Fix this logic -- Group acts have no category stored but
    # nil should not indicate something exists.
    category.present? ? BHOF_CATS[category] : "Unknown"
  end

  def decision_to_s(decision)
    BHOF_FINAL_DECISION[decision]
  end

  def embed_video(url)
    if not url.present?
      return "No Video URL for this application."
    end

    url.gsub!(/^\s+/, "")
    parts = url.split(" ")

    if not parts.nil?
      url=parts[0]
    end

    if url.match(/^http(s)*:\/\/youtu\.be/) or
       url.match(/^http(s)*:\/\/vimeo\.com\/tinyd\//) or
       url.include?("//tinyurl.com/")

      # unpack bit.ly or youtu.be urls
      curl = Curl::Easy.http_get(url)
      http_response, *http_headers = curl.header_str.split(/[\r\n]+/).map(&:strip)
      http_headers = Hash[http_headers.flat_map { |s| s.scan(/^(\S+): (.+)/) }]
      url = http_headers['Location']

      if url.present?
        url.gsub!(/feature=youtu\.be/, "")
        url.gsub!(/&amp;/, "")
        url.gsub!(/&/, "")
      else
        url = ""
      end
    end

    # SECURITY: we wil only embed youtube and vimeo videos, even if
    # tinyurl takes us someplace else
    if url.include?("youtube.com")
      youtube_id = url.split("=").last
      return content_tag(:embed, nil, { src: "//www.youtube.com/embed/#{youtube_id}", width: 420, height: 315 })
    end

    if url.include?("vimeo.com")
      vimeo_id = url.split("/").last
      return content_tag(:embed, nil, { src: "//player.vimeo.com/video/#{vimeo_id}", width: 420, height: 315 })
    end

    return "Embedded video is not available for this URL."
  end
end
