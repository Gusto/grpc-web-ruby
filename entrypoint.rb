#!/usr/bin/env ruby
# frozen_string_literal: true

# Wait for envoy to be ready
require 'net/http'

100.times do |_n|
  begin
    http = Net::HTTP.new('envoy', 8080)
    response = http.request(Net::HTTP::Get.new('/ready'))
    break if response.body != 'no healthy upstream'
  rescue StandardError # rubocop:disable Lint/SuppressedException
    # Intentionally empty, will retry
  end
  sleep 0.1
end

exec(ARGV.join(' '))
