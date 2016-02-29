require "../foreman.cr"
require "./timeout.cr"
require "./process.cr"
require "./procfile.cr"
require "./env.cr"

module Foreman
  class Engine
    # The signals that the engine cares about.
    HANDLED_SIGNALS = [Signal::TERM, Signal::INT, Signal::HUP]
    COLORS = %i(green
     yellow
     blue
     magenta
     cyan
     light_gray
     dark_gray
     light_red
     light_green
     light_yellow
     light_blue
     light_magenta
     light_cyan
    )
    ERROR_COLOR = :red
    SYSTEM_COLOR = :white

    property :writer

    # Create an *Engine* for running processes
    #
    # @param [Hash] options
    #
    # @option options [Fixnum] :port      (5000)     The base port to assign to processes
    # @option options [String] :root      (Dir.pwd)  The root directory from which to run processes
    def initialize
      # _, @output = IO.pipe(write_blocking: true)
      # @output.colorize
      @output = STDOUT
      @channel = Channel(Int32).new
      @processes = [] of Foreman::Process
      @running = {} of Int32 => Foreman::Process
      @terminating = false
      @env = {} of String => String
    end

    # Register processes by reading a Procfile
    #
    # @param [String] filename  A Procfile from which to read processes to register
    def load_procfile(filename : String)
      root = File.dirname(filename)
      Foreman::Procfile.new(filename).entries do |name, command|
        register name, command
      end
    end

    def load_env(filename : String)
      root = File.dirname(filename)
      Foreman::Env.new(filename).entries do |key, value|
        @env[key.to_s] = value.to_s
      end
    end

    # Register a process to be run by this *Engine*
    #
    # @param [String] name     A name for this process
    # @param [String] command  The command to run
    private def register(name : String, command : String)
      @processes << Foreman::Process.new(name, command, @env)
    end


    # Start the processes registered to this *Engine*
    #
    def start
      register_signal_handlers
      spawn_processes
      watch_for_ended_processes
    end

    private def write(string : String, color = SYSTEM_COLOR : Symbol)
      # @writer << string.colorize(color)
      @output << "#{string}\n".colorize(color)
    end

    private def spawn_processes
      @processes.each_with_index do |process, index|
        name = process.name
        color = COLORS[index]
        begin
          process.run do |output, error|
            spawn do
              spawn do
                while process_output = output.gets
                  write build_output(name, process_output), color
                end
              end

              spawn do
                while process_error = error.gets
                  write build_output(name, process_error), ERROR_COLOR
                end
              end

              status = process.wait
              @channel.send process.pid
            end
          end

          @running[process.pid] = process
          write build_output(name, "started with pid #{process.pid}"), color
        rescue #Errno::ENOENT
          write build_output(name, "unknown command: #{process.command}"), ERROR_COLOR
        end
      end
    end

    private def build_output(name, output)
      longest_name = @processes.map { |p| p.name.size }.max

      filler_spaces = ""
      (longest_name - name.size).times do
        filler_spaces += " "
      end

      "#{Time.now.to_s("%H:%M:%S")} #{name} #{filler_spaces}| #{output.to_s}"
    end

    private def watch_for_ended_processes
      if ended_pid = @channel.receive
        ended_process = @running[ended_pid]

        if id = @running.delete ended_pid
          terminate_gracefully
        end

        write build_output(ended_process.name, "exited!")
      end
    end

    private def kill_children(signal = Signal::TERM)
      @running.each do |pid|
        spawn do
          ::Process.kill signal, pid
          @running.delete pid
          @channel.send pid
        end
      end
    end

    private def terminate_gracefully
      return if @terminating
      restore_default_signal_handlers
      @terminating = true

      write "sending SIGTERM to all processes"
      kill_children Signal::TERM

      timeout = 3
      Timeout.timeout(timeout) do
        while @running.size > 0
          print "."
          sleep 0.1
        end
      end
    rescue Timeout::Error
      write "sending SIGKILL to all processes"
      kill_children Signal::KILL
    end


    private def register_signal_handlers
      HANDLED_SIGNALS.each do |signal|
        signal.trap do
          handle_signal(signal)
        end
      end
    end

    private def restore_default_signal_handlers
      HANDLED_SIGNALS.each do |signal|
        signal.reset
      end
    end
    
    private def handle_signal(signal)
      write "."
      case signal
      when Signal::TERM
        write "SIGTERM received"
      when Signal::INT
        write "SIGINT received"
      when Signal::HUP
        write "SIGHUP received"
      else
        write "unhandled signal #{signal}"
      end

      terminate_gracefully
    end

    # Load a .env file into the *env* for this *Engine*
    #
    # @param [String] filename  A .env file to load into the environment
    def load_env(filename)
      Foreman::Env.new(filename).entries do |name, value|
        @env[name] = value
      end
    end
  end
end
