require "../crank.cr"
require "./timeout.cr"
require "./process.cr"
require "./procfile.cr"
require "./env.cr"

module Crank
  class Engine
    # The signals that the engine cares about.
    HANDLED_SIGNALS = [Signal::TERM, Signal::INT, Signal::HUP, Signal::ABRT]
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

    # Initializes the Engine and sets instance variables
    def initialize
      # _, @output = IO.pipe(write_blocking: true)
      # @output.colorize
      @output = STDOUT
      @channel = Channel(Int32).new
      @processes = [] of Crank::Process
      @running = {} of Int32 => Crank::Process
      @terminating = false
      @env = {} of String => String
    end

    # Populate the list of processes from the given Procfile
    # @param [String] filename  A Procfile from which to populate processes
    def load_procfile(filename : String)
      root = File.dirname(filename)
      Crank::Procfile.new(filename).entries do |name, command|
        @processes << Crank::Process.new(name, command, @env)
      end
    end

    # Populate runtime environment variables from a .env file
    # @param [String] filename  A .env file from which to populate ENV variables
    def load_env(filename : String)
      root = File.dirname(filename)
      Crank::Env.new(filename).entries do |key, value|
        @env[key.to_s] = value.to_s
      end
    end

    # Starts the Engine processes and registers handlers
    def start
      delay(2) { terminate_gracefully }
      register_signal_handlers
      spawn_processes
      watch_for_ended_processes
    end

    private def write(string : String, color = SYSTEM_COLOR : Symbol, line_break = true : Bool)
      # @writer << string.colorize(color)
      line_break_string = line_break ? "\n" : ""
      @output << "#{string}#{line_break_string}".colorize(color)
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
                  write build_output(name, process_output), color, false
                end
              end

              spawn do
                while process_error = error.gets
                  write build_output(name, process_error), ERROR_COLOR, false
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
          begin
            ::Process.kill signal, pid
          rescue
            if signal == Signal::TERM
              kill_children Signal::KILL
            end
          end

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

      timeout = 60

      timeout_error_handler = -> do
        write "sending SIGKILL to all processes"
        kill_children Signal::KILL
      end

      Timeout.timeout(timeout, timeout_error_handler) do
        while @running.size > 0
          print "."
          sleep 0.1
        end
      end
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
  end
end
