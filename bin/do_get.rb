#!/usr/bin/env ruby

Bundler.setup
Bundler.require

argv = ARGV.dup
slop = Slop.new(:strict => true, :help => true)
slop.banner '$ do_get.rb [options]'
slop.on :t, :timeout=, 'timeout in second (default: 10s)', :default => 10
slop.on :i, :inputfile=, 'url list file'
slop.on :n, 'dry-run mode. just print out the result, do not post data to GrowthForecast'
slop.on :d, 'debug', 'debug output'

begin
  slop.parse!(argv)
rescue => e
  puts e
  exit!
end
$opts = slop.to_hash
$opts.delete(:help)

uris = open($opts[:inputfile]).readlines.map{|uri| uri.chomp }
pending = uris.size

EM.run do
  uris.each do |uri|
    http = EM::HttpRequest.new(uri, :connect_timeout => $opts[:timeout], :inactivity_timeout => $opts[:timeout]).get
    http.callback do
      puts "#{uri} #{http.response_header.status}"
      pending -= 1
      EM.stop if pending < 1
    end
    http.errback do
      puts "#{uri} #{http.error}"
      pending -= 1
      EM.stop if pending < 1
    end
  end
end
