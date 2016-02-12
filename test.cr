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

commands = ["ping -c 5 google.com", "ping -c 5 pizzahut.com"]
channel = Channel(String).new

commands.each_with_index do |command, index|
  _, output = IO.pipe(write_blocking: true)
  output.colorize
  color = colors[index]

  spawn do
    process = Process.new(command, shell: true, input: true, output: nil, error: true)
    output = process.output.gets
    STDOUT << output.to_s.colorize(color)
    status = process.wait
    # $? = status
    # output
    channel.send "Done"
  end
end

commands.each do
  puts channel.receive.colorize
end