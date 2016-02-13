require "colorize"

system_color = :white
error_color = :red
colors = %i(green
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

commands = [["google", "ping -c 5 google.com"], ["pizzahut", "ping -c 5 pizzahut.com"]]
channel = Channel(Bool).new

def build_output(name, output, commands)
  names = commands.map { |c| c.first }
  longest_name = names.map { |n| n.size }.max

  filler_spaces = ""
  (longest_name - name.size).times do
    filler_spaces += " "
  end

  "#{Time.now.to_s("%H:%M:%S")} #{name} #{filler_spaces}| #{output.to_s}"
end

commands.each_with_index do |signature, index|
  name = signature[0]
  command = signature[1]
  _, output = IO.pipe(write_blocking: true)
  output.colorize
  color = colors[index]

  spawn do
    process = Process.new(command, shell: true, input: false, output: nil, error: nil)
    while output = process.output.gets
      STDOUT << build_output(name, output, commands).colorize(color)
    end
    status = process.wait
    # $? = status
    # output
    channel.send true
  end
end

commands.each do
  channel.receive
end

puts "DONE"