json.array!(@bhof_members) do |bhof_member|
  json.extract! bhof_member, :id
  json.url bhof_member_url(bhof_member, format: :json)
end
