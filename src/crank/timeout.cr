module Timeout
  def self.timeout(seconds, timeout_handler, &block)
    return block.call if seconds == nil || seconds == 0

    timeout_thread = delay(seconds) { timeout_handler.call }
    block.call
  end
end
