require "../foreman.cr"
require "./helpers.cr"
require "./engine.cr"
require "./engine/cli.cr"

# require "foreman/export"
# require "foreman/version"
# require "shellwords"
# require "yaml"

class Foreman::CLI
  def self.start(process = nil)
    check_procfile!
    engine = Foreman::Engine::CLI.new
    engine.load_procfile(procfile)
    # engine.options[:formation] = "#{process}=1" if process
    engine.start
  end

  def self.error(message)
    puts "ERROR: #{message}"
    exit 1
  end

  def self.check_procfile!
    error("#{procfile} does not exist.") unless File.exists?(procfile)
  end

  def self.procfile
    "Procfile"
  end
end
