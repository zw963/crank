module Foreman
  class Procfile
    # Initialize and load commands from a Procfile
    #
    # @param [String] filename (nil)  An optional filename to read from
    def initialize(filename = nil : String)
      @entries = [] of Array(String)
      load(filename) if filename
    end

    # Yield each *Procfile* entry in order
    def entries(&blk)
      @entries.each do |entry|
        name = entry[0]
        command = entry[1]
        yield name, command
      end
    end

    # Retrieve a *Procfile* command by name
    #
    # @param [String] name  The name of the Procfile entry to retrieve
    def [](name : String)
      @entries[name]
    end

    # Create a *Procfile* entry
    #
    # @param [String] name     The name of the *Procfile* entry to create
    # @param [String] command  The command of the *Procfile* entry to create
    def []=(name : String, command : String)
      @entries[name] = command
    end

    # Load a Procfile from a file
    #
    # @param [String] filename  The filename of the *Procfile* to load
    def load(filename)
      @entries = parse(filename)
    end

    private def parse(filename)
      File.read(filename).gsub("\r\n", "\n").split("\n").map do |line|
        if line =~ /^([A-Za-z0-9_-]+):\s*(.+)$/
          [$1, $2]
        end
      end.compact
    end
  end
end
