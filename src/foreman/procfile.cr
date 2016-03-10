module Foreman
  class Procfile
    # Initialize and load commands from a Procfile
    # @param [String] filename  The filename
    def initialize(filename : String)
      @entries = [] of Array(String)
      load(filename) if filename
    end

    # Yield each *Procfile* entry with name and command
    def entries(&block)
      @entries.each do |entry|
        name = entry[0]
        command = entry[1]
        yield name, command
      end
    end

    private def load(filename)
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
