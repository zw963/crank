module Foreman
  class Process
    getter :command, :name

    def initialize(name : String, command : String, env = {} of String => String)
      @name = name
      @command = command
      @process = ::Process.new(command, env: env, shell: true, input: false, output: nil, error: nil)
    end

    def run
      yield @process.output, @process.error
    end

    def wait
      @status ||= @process.wait
    end

    def pid
      @process.pid
    end
  end
end