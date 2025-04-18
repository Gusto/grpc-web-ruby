# frozen_string_literal: true

require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'

Capybara.register_driver :selenium_chrome_standalone do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--window-size=2000,1280')

  host = ENV.fetch('SELENIUM_HOST', 'localhost')
  port = ENV.fetch('SELENIUM_PORT', 4444)
  url = "http://#{host}:#{port}/wd/hub"

  Capybara::Selenium::Driver.new(app, browser: :remote, url:, options:)
end

Capybara.configure do |config|
  config.server = :webrick
  config.server_host = IPSocket.getaddress(Socket.gethostname)
  config.server_port = '3010'
  config.app_host = "http://#{Socket.gethostname}:#{Capybara.server_port}"
  config.always_include_port = true

  if ENV['CI'] || ENV['DOCKER']
    config.javascript_driver = :selenium_chrome_standalone
  elsif ENV['CHROME']
    config.javascript_driver = :selenium_chrome
  else
    config.javascript_driver = :selenium_chrome_headless
  end

  puts "Capybara is using the #{config.javascript_driver} driver for javascript tests"
end

# Remove when Capybara is updated
# https://github.com/puzzle/skills/issues/800
Selenium::WebDriver.logger.ignore(:clear_local_storage, :clear_session_storage)

RSpec.configure do |config|
  config.before(type: :feature) { Capybara.app = TestGRPCWebApp.build }
end
