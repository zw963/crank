module Foreman
  class Process
    property :command

    def initialize(command : String)
      @command = command
      @process = ::Process.new(command, shell: true, input: false, output: nil, error: nil)
    end

    def run
      yield @process.output
    end

    def wait
      @process.wait
    end

    def pid
      @process.pid
    end
  end
end