# start from this frame (use "root" for all, or e.g. a specific frame: 
# "org.apache.catalina.core.StandardContextValve.invoke(StandardContextValve.java:174)")
START_FRAME = "root"

# don't draw/follow branches with a lower count than this
MIN_BRANCH_COUNT = 8

# frame colors for matching frames (e.g.: { /java\.lang/ => "red", /java\.math/ => "#0000FF" })
COLORS = {}

require 'java_stack'

if ARGV.length != 2
  puts "ruby thread_graph.rb marshal_input_file output_file.dot"
  exit
end

if !File.exist?(ARGV[0])
  puts "File #{ARGV[0]} doesn't exist"
  exit
end

METHOD = /(.*)\.(.*\..*\(.*)/

# create a label for the frame to show the runnable count, overall count, and split the 
# object call from the package name for better spacing
def label(frame)
  counts = "#{frame.runnable_count} | #{frame.count} |"
  if frame.java_code =~ METHOD
    java_pkg = $1
    obj_code = $2
    obj_code.sub!(/</, "\\<")
    obj_code.sub!(/>/, "\\>")
    return counts + java_pkg + "\\n" + obj_code
  end
  return counts + frame.java_code
end

# color the frame according to the COLORS map
def color(frame)
  COLORS.each_pair do |criteria, color|
    if frame.java_code =~ criteria
      return ",color=\"#{color}\""
    end
  end
  return ""
end

$processed = {}

# create the dot output for a particular frame
def create_dot(file, frame)
  #frame might be reached through multiple branches, so only draw once
  return if $processed[frame]
  
  # draw the block for this frame
  file.puts "\"#{frame.java_code}\" [label=\"#{label(frame)}\"#{color(frame)}];"
  $processed[frame] = true
  
  return if frame.branches.size == 0
  
  # draw all the branches
  frame.branches.values.each do |branch|
    next if branch.count < MIN_BRANCH_COUNT
    file.puts "\"#{frame.java_code}\" -> \"#{branch.frame.java_code}\" [label=\"#{branch.count}\",weight=#{branch.count}#{color(branch.frame)}];"
  end
  
  # recurse on each branch's frame
  frame.branches.values.each do |branch|
    next if branch.count < MIN_BRANCH_COUNT
    create_dot(file, branch.frame)
  end
end

graph = Marshal.load(File.open(ARGV[0], "rb"))

File.open(ARGV[1], "w") do |file|
  file.puts "digraph calltree {"
  file.puts "node [shape=record];"
  create_dot(file, graph[START_FRAME])
  file.puts "}"
end
