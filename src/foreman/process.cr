require "../foreman.cr"

class Foreman::Process
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

  # Get environment-expanded command for a +Process+
  #
  # @param [Hash] custom_env ({}) Environment variables to merge with defaults
  #
  # @return [String]  The expanded command
  #
  def expanded_command(custom_env = Hash.new)
    env = @options[:env].merge(custom_env)
    expanded_command = command.dup
    env.each do |key, val|
      expanded_command.gsub!("$#{key}", val)
    end
    expanded_command
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
  def run(options = Hash.new)
    env = @options[:env].merge(options[:env] || Hash.new)
    output = options[:output] || $stdout
    runner = "#{Foreman.runner}".shellescape
    Dir.chdir(cwd) do
      Process.spawn env, expanded_command(env), {:out => output, :err => output}
    end
  end

  # Exec a +Process+
  #
  # @param [Hash] options
  #
  # @option options :env ({}) Environment variables to set for this execution
  #
  # @return Does not return
  def exec(options = Hash.new)
    env = @options[:env].merge(options[:env] || Hash.new)
    env.each { |k, v| ENV[k] = v }
    Dir.chdir(cwd)
    Kernel.exec expanded_command(env)
  end

  # Returns the working directory for this +Process+
  #
  # @returns [String]
  #
  def cwd
    File.expand_path(@options[:cwd] || ".")
  end
end
