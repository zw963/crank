module Foreman
  class Procfile
    # Initialize a Procfile
    #
    # @param [String] filename (nil)  An optional filename to read from
    #
    def initialize(filename = nil)
      @entries = [] of Array(String)
      load(filename) if filename
    end

    # Yield each +Procfile+ entry in order
    #
    def entries(&blk)
      @entries.each do |entry|
        yield entry[0], entry[1]
      end
    end

    # Retrieve a +Procfile+ command by name
    #
    # @param [String] name  The name of the Procfile entry to retrieve
    #
    def [](name)
      if entry = @entries.detect { |n, c| name == n }
        entry.last
      end
    end

    # Create a +Procfile+ entry
    #
    # @param [String] name     The name of the +Procfile+ entry to create
    # @param [String] command  The command of the +Procfile+ entry to create
    #
    def []=(name, command)
      delete name
      @entries << [name, command]
    end

    # Remove a +Procfile+ entry
    #
    # @param [String] name  The name of the +Procfile+ entry to remove
    #
    def delete(name)
      @entries.reject! { |n, c| name == n }
    end

    # Load a Procfile from a file
    #
    # @param [String] filename  The filename of the +Procfile+ to load
    #
    def load(filename)
      @entries = parse(filename)
    end

    # Save a Procfile to a file
    #
    # @param [String] filename  Save the +Procfile+ to this file
    #
    def save(filename)
      File.open(filename, 'w') do |file|
        file.puts self.to_s
      end
    end

    # Get the +Procfile+ as a +String+
    #
    def to_s
      @entries.map do |name, command|
        [name, command].join(": ")
      end.join("\n")
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
