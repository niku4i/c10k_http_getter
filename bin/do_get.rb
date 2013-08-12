#!/usr/bin/env ruby

Bundler.setup
Bundler.require

argv = ARGV.dup
slop = Slop.new(:strict => true, :help => true)
slop.banner '$ do_get.rb [options]'
slop.on :t, :timeout=, 'timeout in second (default: 10s)', :default => 10
slop.on :c, :concurrency=, 'concurrent connection', :default => 64
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

EM.run do
  EM::Iterator.new(uris, $opts[:conncurrency]).each(
    proc {|uri, iter|
      http = EM::HttpRequest.new(uri, :connect_timeout => $opts[:timeout], :inactivity_timeout => $opts[:timeout]).get
      http.callback do
        puts "#{uri} #{http.response_header.status}"
        iter.next
      end
      http.errback do
        puts "#{uri} #{http.error}"
        iter.next
      end
    },
    proc {
      puts "All done!"
      EM.stop
    }
  )
end
