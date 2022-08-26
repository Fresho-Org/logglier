$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'logglier'
require 'stringio'

module LoggerHacks
  def logdev
    @logdev
  end
end

class MockTCPSocket
  def initialize(*args); end
  def setsockopt(*args); end
  def send(*args); end
end

class MockNetHTTPProxy
  def initialize(*args); end
  def deliver(*args); end
end

RSpec.configure do |config|
  config.color = true
  config.add_formatter('documentation')

  config.before(:each) do
  end

  def new_logglier(url,opts={})
    log = Logglier.new(url,opts)
    log.extend(LoggerHacks)
  end

end
