json.array!(@signup_invites) do |signup_invite|
  json.extract! signup_invite, :id, :code, :available, :expires, :used_count
  json.url signup_invite_url(signup_invite, format: :json)
end
