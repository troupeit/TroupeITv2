module ApplicationHelper
  include TimeTools

  # TODO: MOVE THESE TO THEIR APPROPRIATE MODELS.
  # company membership access levels, used by events
  ::CMACCESS = { 0 => 'Performer',
                 2 => 'Tech Crew',
                 4 => 'Stage Manager',
                 8 => 'Producer' }

  ::CM_PERFORMER = 0
  ::CM_TECHCREW  = 2
  ::CM_STAGEMGR  = 4
  ::CM_PRODUCER  = 8

  ::INVITE_TYPE = { 0 => 'User to User',
                    1 => 'User to Email',
                    128 => 'System' }

  ::INVITE_USER     = 0
  ::INVITE_EMAIL    = 1
  ::INVITE_COMPANY  = 128

  def bytes_to_bp(sz)
    # return a file size in binary prefix notation, SI units
    bprefix = Array.new

    bprefix[0] = "KiBi"
    bprefix[1] = "MiBi"
    bprefix[2] = "GiBi"
    bprefix[3] = "TiBi"
    bprefix[4] = "PiBi"
    bprefix[5] = "EiBi"
    bprefix[6] = "ZiBi"
    bprefix[7] = "YiBi"

    i = 1
    bprefix.each { |k|
      v = 1024 ** i
      if sz < 1024 ** (i+1)
        return sprintf("%.03f %s", sz.to_f / v.to_f, k)
      end
      i = i + 1
    }
  end
end
