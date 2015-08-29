#
# Sample Asynchronous Consumer:
#   Retrieve all messages from the queue in a separate thread
#
require 'jms'
require 'yaml'

jms_provider = ARGV[0] || 'activemq'

# Load Connection parameters from configuration file
config       = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'jms.yml'))[jms_provider]
raise "JMS Provider option:#{jms_provider} not found in jms.yml file" unless config

continue = true

trap('INT') {
  JMS.logger.info 'CTRL + C'
  continue = false
}

# Consume all available messages on the queue
JMS::Connection.start(config) do |connection|

  # Define Asynchronous code block to be called every time a message is received
  connection.on_message(queue_name: 'ExampleQueue') do |message|
    JMS.logger.info message.inspect
  end

  # Since the on_message handler above is in a separate thread the thread needs
  # to do some other work. For this example it will just sleep for 10 seconds
  while (continue)
    sleep 10
  end

  JMS.logger.info 'closing ...'
end
