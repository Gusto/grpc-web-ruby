# frozen_string_literal: true

require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver :selenium_chrome_standalone do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--window-size=2000,1280')
  # Enable browser logging
  options.add_option('goog:loggingPrefs', { browser: 'ALL', performance: 'ALL' })

  host = ENV.fetch('SELENIUM_HOST', 'localhost')
  port = ENV.fetch('SELENIUM_PORT', 4444)
  url = "http://#{host}:#{port}/wd/hub"

  # Wait for Selenium to be ready
  require 'net/http'
  require 'uri'
  max_attempts = 30
  attempt = 0
  loop do
    attempt += 1
    begin
      uri = URI("#{url}/status")
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 5
      http.read_timeout = 5
      response = http.get(uri.path)
      break if response.code == '200'
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Net::OpenTimeout, Net::ReadTimeout
      # Selenium not ready yet
    end
    raise "Selenium not ready after #{max_attempts} attempts" if attempt >= max_attempts

    sleep 1
  end

  # Configure timeouts
  http_client = Selenium::WebDriver::Remote::Http::Default.new
  http_client.open_timeout = 10
  http_client.read_timeout = 30

  Capybara::Selenium::Driver.new(app, browser: :remote, url:, options:, http_client:)
end

Capybara.configure do |config|
  config.server = :webrick
  config.always_include_port = true

  if ENV['CI'] || ENV['DOCKER']
    # In Docker/CI, bind to all interfaces
    # Use the container's hostname which docker compose --use-aliases makes resolvable
    config.server_host = '0.0.0.0'
    config.default_driver = :selenium_chrome_standalone
    config.javascript_driver = :selenium_chrome_standalone
  else
    config.server_host = IPSocket.getaddress(Socket.gethostname)
    config.app_host = "http://#{Socket.gethostname}"
    if ENV['CHROME']
      config.javascript_driver = :selenium_chrome
    else
      config.javascript_driver = :selenium_chrome_headless
    end
  end

  puts "Capybara is using the #{config.javascript_driver} driver for javascript tests"
end

# Remove when Capybara is updated
# https://github.com/puzzle/skills/issues/800
Selenium::WebDriver.logger.ignore(:clear_local_storage, :clear_session_storage)

# Helper module for getting the correct server host in different environments
module CapybaraServerHelper
  def self.server_host_for_client(server)
    # In Docker, use localhost since client runs in same container as server
    if ENV['CI'] || ENV['DOCKER']
      '127.0.0.1'
    else
      server.host
    end
  end

  def self.server_host_for_browser(_server)
    # In Docker, use the container's hostname since docker compose --use-aliases makes it resolvable
    if ENV['CI'] || ENV['DOCKER']
      Socket.gethostname
    else
      Capybara.server_host
    end
  end
end

RSpec.configure do |config|
  config.before(type: :feature) { Capybara.app = TestGRPCWebApp.build }

  # Explicitly quit the WebDriver session after each test to free Selenium resources
  config.after(type: :feature) do
    begin
      Capybara.current_session.driver.quit if Capybara.current_session.driver.respond_to?(:quit)
    rescue StandardError
      # Ignore cleanup errors
    end
  end

  # Print browser console logs on test failure for debugging
  config.after(type: :feature) do |example|
    if example.exception && page.driver.browser.respond_to?(:logs)
      begin
        logs = page.driver.browser.logs.get(:browser)
        if logs.any?
          puts "\n=== Browser Console Logs ==="
          logs.each { |log| puts "  [#{log.level}] #{log.message}" }
          puts "=== End Browser Console Logs ===\n"
        end
      rescue StandardError => e
        puts "Could not retrieve browser logs: #{e.message}"
      end
    end
  end
end
