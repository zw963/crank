require "../foreman.cr"

module Foreman
  class Process
    property :command

    # Create a Process
    #
    # @param [String] command  The command to run
    # @param [Hash]   options
    #
    # @option options [String] :cwd (./)  Change to this working directory before executing the process
    # @option options [Hash]   :env ({})  Environment variables to set for this process
    #
    def initialize(command, options = Hash.new)
      @command = command
      @options = options.dup
    end

    # Run a +Process+
    #
    # @param [Hash] options
    #
    # @option options :env    ({})       Environment variables to set for this execution
    # @option options :output ($stdout)  The output stream
    #
    # @returns [Fixnum] pid  The +pid+ of the process
    #
    def run(output : IO::FileDescriptor, env : String)
      # runner = "#{Foreman.runner}"
      Dir.cd(cwd)
      ::Process.run command, output: output, error: output
    end

    # Returns the working directory for this +Process+
    #
    # @returns [String]
    #
    def cwd
      File.expand_path(@options[:cwd] || ".")
    end
  end
end
