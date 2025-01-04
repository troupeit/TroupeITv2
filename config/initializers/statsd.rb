# Sets up a UDP backend. First argument is the UDP address to send
# StatsD packets to, second argument specifies the protocol variant
# (i.e. `:statsd`, `:statsite`, or `:datadog`).

# This is no longer necessary?
# StatsD.backend = StatsD::Instrument::Backends::UDPBackend.new("127.0.0.1:8125", :datadog)
