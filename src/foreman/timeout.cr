module Timeout
  def self.timeout(seconds, &block)
    return block.call if seconds == nil || seconds == 0

    error = Error.new("execution expired")

    channel = Channel(Bool).new
    spawn do
      sleep seconds
      puts "done sleeping"
      channel.send false
    end

    spawn do
      puts "yielding"
      block.call
      channel.send true
    end

    puts channel.receive
    # if value = channel.receive
    #   if value == true
    #     puts "true"
    #   else
    #     puts "false"
    #   end
    #   channel.close
    # end
    # puts "listening"
    # if channel.receive == true
    #   puts "true"
    #   channel.close
    # elsif channel.receive == false
    #   puts "false"
    #   channel.close
    #   raise error
    # else
    #   puts "Asdf"
    # end
  end

  class Error < Exception
  end
end