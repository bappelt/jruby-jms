module JMS

  private

  # For internal use only by JMS::Connection
  class MessageListenerImpl
    include JMS::MessageListener

    # Parameters:
    #   :statistics Capture statistics on how many messages have been read
    #      true  : This method will capture statistics on the number of messages received
    #              and the time it took to process them.
    #              The timer starts when the listener instance is created and finishes when either the last message was received,
    #              or when Destination::statistics is called. In this case MessageConsumer::statistics
    #              can be called several times during processing without affecting the end time.
    #              Also, the start time and message count is not reset until MessageConsumer::each
    #              is called again with statistics: true
    #
    #              The statistics gathered are returned when statistics: true and async: false
    def initialize(params={}, &proc)
      @proc = proc

      if params[:statistics]
        @message_count = 0
        @start_time    = Time.now
      end
    end

    # Method called for every message received on the queue
    # Per the JMS specification, this method will be called sequentially for each message on the queue.
    # This method will not be called again until its prior invocation has completed.
    # Must be onMessage() since on_message() does not work for interface methods that must be implemented
    def onMessage(message)
      begin
        if @message_count
          @message_count += 1
          @last_time     = Time.now
        end
        @proc.call message
      rescue SyntaxError, NameError => boom
        JMS.logger.error "Unhandled Exception processing JMS Message. Doesn't compile: " + boom
        JMS.logger.error "Ignoring poison message:\n#{message.inspect}"
        JMS.logger.error boom.backtrace.join("\n")
      rescue StandardError => bang
        JMS.logger.error "Unhandled Exception processing JMS Message. Doesn't compile: " + bang
        JMS.logger.error "Ignoring poison message:\n#{message.inspect}"
        JMS.logger.error bang.backtrace.join("\n")
      rescue Exception => exc
        JMS.logger.error "Unhandled Exception processing JMS Message. Exception occurred:\n#{exc}"
        JMS.logger.error "Ignoring poison message:\n#{message.inspect}"
        JMS.logger.error exc.backtrace.join("\n")
      end
    end

    # Return Statistics gathered for this listener
    def statistics
      raise(ArgumentError, 'First call MessageConsumer::on_message with :statistics=>true before calling MessageConsumer::statistics()') unless @message_count
      duration = (@last_time || Time.now) - @start_time
      {
        messages:            @message_count,
        duration:            duration,
        messages_per_second: (@message_count/duration).to_i
      }
    end
  end
end
