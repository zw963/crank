module Foreman
  class Env
    def initialize(filename = nil : String)
      @entries = [] of Array(String)
      load(filename) if filename
    end

    # Yield each *Procfile* entry in order
    def entries(&block)
      @entries.each do |entry|
        key = entry[0]
        value = entry[1]
        yield key, value
      end
    end

    def load(filename)
      @entries = parse(filename)
    end

    private def parse(filename)
      if File.exists?(filename)
        File.read(filename).gsub("\r\n","\n").split("\n").map do |line|
          if line =~ /\A([A-Za-z_0-9]+)=(.*)\z/
            key = $1
            case value = $2.rstrip
            # Remove single quotes
            when /\A'(.*)'\z/ then value = $1
            # Remove double quotes and unescape string preserving newline characters
            when /\A"(.*)"\z/ then value = $1.gsub('\n', "\n").gsub(/\\(.)/, '\1')
            end
            [key, value]
          end
        end.compact
      else
        Array(String).new
      end
    end
  end
end
