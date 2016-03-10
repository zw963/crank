module Timeout
  def self.timeout(seconds, &block)
    return block.call if seconds == nil || seconds == 0

    error = Error.new("execution expired")

    channel = Channel(Bool).new
    spawn do
      sleep seconds
      channel.send false
    end

    spawn do
      block.call
      channel.send true
    end
  end

  class Error < Exception
  end
end
