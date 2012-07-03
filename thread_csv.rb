#Creates a simple csv with stack frames sorted by overall count, and their branches listed in the same row
require './java_stack'

if ARGV.length != 2
  puts "ruby thread_csv.rb marshal_file output_file.csv"
  exit
end

if !File.exist?(ARGV[0])
  puts "File #{ARGV[0]} doesn't exist"
  exit
end

graph = Marshal.load(File.open(ARGV[0], "rb"))

File.open(ARGV[1], "w") do |file|

  graph.values.sort {|a,b| b.count <=> a.count }.each do |frame|
    next if frame.java_code == "root"
    file.write "\"#{frame.java_code}\",#{frame.count},#{frame.runnable_count}"
    frame.branches.values.sort {|a,b| b.count <=> a.count }.each do |branch|
      file.write ",\"#{branch.frame.java_code}\",#{branch.count}"
    end
    file.write "\n"
  end
  
end
