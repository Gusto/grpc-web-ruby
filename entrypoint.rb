#!/usr/bin/env ruby

# Wait for envoy to be ready
require "net/http"

100.times do |n|

  uri = URI.parse('http://envoy:9901/ready')
  begin
    http = Net::HTTP.new('envoy', 8080)
    response = http.request(Net::HTTP::Get.new('/ready'))
    break if response.body != 'no healthy upstream'
  rescue => e
    response = nil
  end
  sleep 0.1
end

exec(ARGV.join(' '))
