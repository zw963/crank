require "colorize"
require "../crank.cr"
require "./engine.cr"

module Crank
  class CLI
    ERROR_COLOR = :red

    def self.start(process = nil)
      check_procfile!
      engine = Crank::Engine.new
      engine.load_env(dotenv)
      engine.load_procfile(procfile)
      engine.start
    end

    def self.error(message)
      puts "ERROR: #{message}".colorize(ERROR_COLOR)
      exit 1
    end

    def self.check_procfile!
      error("#{procfile} does not exist.") unless File.exists?(procfile)
    end

    def self.procfile
      "Procfile"
    end

    def self.dotenv
      ".env"
    end
  end
end
