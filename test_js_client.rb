# Require the gems
# require 'capybara/poltergeist'
#
# # Configure Poltergeist to not blow up on websites with js errors aka every website with js
# # See more options at https://github.com/teampoltergeist/poltergeist#customization
# Capybara.register_driver :poltergeist do |app|
#   Capybara::Poltergeist::Driver.new(app, js_errors: false)
# end
#
# # Configure Capybara to use Poltergeist as the driver
# Capybara.default_driver = :poltergeist

require 'capybara/apparition'
Capybara.default_driver = :apparition

browser = Capybara.current_session

browser.visit url

browser.visit "file://#{File.expand_path('spec/js-client/test.html')}"

test_script = <<-EOF
x = new HelloRequest();
x.setName('James');
window.helloService.sayHello(x, {}, function(err, response){ window.grpcResponse = response; });
EOF

browser.execute_script(test_script)
sleep 1
browser.evaluate_script("window.grpcResponse.toObject()")
