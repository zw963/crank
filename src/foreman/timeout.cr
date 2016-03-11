module Timeout
  def self.timeout(seconds, error_handler, &block)
    return block.call if seconds == nil || seconds == 0

    # error = TimeoutError.new("execution expired")

    timeout_thread = delay(seconds) { error_handler.call }
    block.call

    # while !timeout_reached
    # end

    # execution_thread
    # channel = Channel(Bool).new
    # execution_thread = spawn do
    #   channel.send true
    # end

    # timer_thread = spawn do
    #   sleep seconds
    #   channel.send false
    # end

    # channel_response = channel.receive
    # channel.close

    # if channel_response == false

    # end
  end

  class TimeoutError < Exception
    def initialize(message = "Timeout reached")
      super(message)
    end
  end
end
