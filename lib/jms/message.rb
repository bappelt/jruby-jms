# Extend JMS Message Interface with Ruby methods
#
# A Message is the item that can be put on a queue, or obtained from a queue.
#
# A Message consists of 3 major parts:
#   - Header
#     Accessible as attributes of the Message class
#   - Properties
#     Accessible via [] and []= methods
#   - Data
#     The actual data portion of the message
#     See the specific message types for details on how to access the data
#     portion of the message
#
# For further help on javax.jms.Message
#   http://download.oracle.com/javaee/6/api/index.html?javax/jms/Message.html
#
# Interface javax.jms.Message
module JMS::Message

  # Methods directly exposed from the Java class:

  # call-seq:
  #   acknowledge
  #
  # Acknowledges all consumed messages of the session of this consumed message
  #

  # call-seq:
  #   clear_body
  #
  #  Clears out the message body
  #

  # call-seq:
  #   clear_properties
  #
  #  Clears out the properties of this message
  #

  # For Backward compatibility with JRuby prior to 1.6
  # JRuby 1.6 now does all this for us. Thank you headius :)
  unless self.instance_methods.include? :jms_delivery_mode

    # Header Fields - Attributes of the message

    # Returns the JMS Delivery Mode
    # One of the following will be returned
    #   JMS::DeliveryMode::PERSISTENT
    #   JMS::DeliveryMode::NON_PERSISTENT
    def jms_delivery_mode
      getJMSDeliveryMode
    end

    # Set the JMS Delivery Mode
    # Values can be
    #   JMS::DeliveryMode::PERSISTENT
    #   JMS::DeliveryMode::NON_PERSISTENT
    def jms_delivery_mode=(mode)
      raise "Sorry, due to incompatibility with JRuby 1.6, please call jms_delivery_mode_sym when using symbols" if mode.is_a? Symbol
      self.setJMSDeliveryMode(mode)
    end

    # Is the message persistent?
    def persistent?
      getJMSDeliveryMode == JMS::DeliveryMode::PERSISTENT
    end

    # Returns the Message correlation ID as a String
    # The resulting string may contain nulls
    def jms_correlation_id
      String.from_java_bytes(getJMSCorrelationIDAsBytes) if getJMSCorrelationIDAsBytes
    end

    # Set the Message correlation ID
    #   correlation_id: String
    # Also supports embedded nulls within the correlation id
    def jms_correlation_id=(correlation_id)
      setJMSCorrelationIDAsBytes(correlation_id.nil? ? nil : correlation_id.to_java_bytes)
    end

    # Returns the Message Destination
    #  Instance of JMS::Destination
    def jms_destination
      getJMSDestination
    end

    # Set the Message Destination
    #   jms_destination: Must be an instance of JMS::Destination
    def jms_destination=(destination)
      setJMSDestination(destination)
    end

    # Return the message expiration value as an Integer
    def jms_expiration
      getJMSExpiration
    end

    # Set the Message expiration value
    #   expiration: Integer
    def jms_expiration=(expiration)
      setJMSExpiration(expiration)
    end

    # Returns the Message ID as a String
    # The resulting string may contain embedded nulls
    def jms_message_id
      getJMSMessageID
    end

    # Set the Message correlation ID
    #   message_id: String
    # Also supports nulls within the message id
    def jms_message_id=(message_id)
      setJMSMessageID(message_id)
    end

    # Returns the Message Priority level as an Integer
    def jms_priority
      getJMSPriority
    end

    # Set the Message priority level
    #   priority: Integer
    def jms_priority=(priority)
      setJMSPriority(priority)
    end

    # Indicates whether the Message was redelivered?
    def jms_redelivered?
      getJMSRedelivered
    end

    # Set whether the Message was redelivered
    #   bool: Boolean
    def jms_redelivered=(bool)
      setJMSPriority(bool)
    end

    # Returns the Message reply to Destination
    #  Instance of JMS::Destination
    def jms_reply_to
      getJMSReplyTo
    end

    # Set the Message reply to Destination
    #   reply_to: Must be an instance of JMS::Destination
    def jms_reply_to=(reply_to)
      setJMSReplyTo(reply_to)
    end

    # Returns the Message timestamp as Java Timestamp Integer
    #TODO Return Ruby Time object?
    def jms_timestamp
      getJMSTimestamp
    end

    # Set the Message timestamp as Java Timestamp Integer
    #   timestamp: Must be an Java Timestamp Integer
    #TODO Support Ruby Time
    def jms_timestamp=(timestamp)
      setJMSTimestamp(timestamp)
    end

    # Returns the Message type supplied by the client when the message was sent
    def jms_type
      getJMSType
    end

    # Sets the Message type
    #   type: String
    def jms_type=(type)
      setJMSType(type)
    end
  end

  # Return the JMS Delivery Mode as a Ruby symbol
  #   :persistent
  #   :non_persistent
  #   nil if unknown
  def jms_delivery_mode_sym
    case jms_delivery_mode
    when JMS::DeliveryMode::PERSISTENT
      :persistent
    when JMS::DeliveryMode::NON_PERSISTENT
      :non_persistent
    else
      nil
    end
  end

  # Set the JMS Delivery Mode from a Ruby Symbol
  # Valid values for mode
  #   :persistent
  #   :non_persistent
  def jms_delivery_mode_sym=(mode)
    val =
      case mode
      when :persistent
        JMS::DeliveryMode::PERSISTENT
      when :non_persistent
        JMS::DeliveryMode::NON_PERSISTENT
      else
        raise "Unknown delivery mode symbol: #{mode}"
      end
    self.setJMSDeliveryMode(val)
  end

  # Return the attributes (header fields) of the message as a Hash
  def attributes
    {
      jms_correlation_id:    jms_correlation_id,
      jms_delivery_mode_sym: jms_delivery_mode_sym,
      jms_destination:       jms_destination.nil? ? nil : jms_destination.to_string,
      jms_expiration:        jms_expiration,
      jms_message_id:        jms_message_id,
      jms_priority:          jms_priority,
      jms_redelivered:       jms_redelivered?,
      jms_reply_to:          jms_reply_to,
      jms_timestamp:         jms_timestamp,
      jms_type:              jms_type,
    }
  end

  # Methods for manipulating the message properties

  # Get the value of a property
  def [](key)
    getObjectProperty key.to_s
  end

  # Set a property
  def []=(key, value)
    setObjectProperty(key.to_s, value)
  end

  # Does message include specified property?
  def include?(key)
    # Ensure a Ruby true is returned
    property_exists(key) == true
  end

  # Return Properties as a hash
  def properties
    h = {}
    properties_each_pair { |k, v| h[k]=v }
    h
  end

  # Set Properties from an existing hash
  def properties=(h)
    clear_properties
    h.each_pair { |k, v| setObjectProperty(k.to_s, v) }
    h
  end

  # Return each name value pair
  def properties_each_pair(&proc)
    enum = getPropertyNames
    while enum.has_more_elements
      key = enum.next_element
      proc.call key, getObjectProperty(key)
    end
  end

  def inspect
    "#{self.class.name}: #{data}\nAttributes: #{attributes.inspect}\nProperties: #{properties.inspect}"
  end

end
