# only include threads where at least one stack frame matches this regex, e.g. /StandardContextValve.java:174/
STACK_INCLUSION = // #always matches

# stack frames that match this regex will simply be ignored (elided from the stack), e.g.
# /springframework\.aop|TransactionInterceptor|\$Proxy\d+\..*Unknown Source|java\.lang\.reflect|sun\.reflect/
ELIDE_FRAME = /a^/ #never matches

require 'java_stack'

if ARGV.length != 2
  puts "ruby thread_dump.rb logfile_input marshal_output_file_name"
  exit
end

def each_stack_line(file)
  while (line = file.gets)
    if (line != "\n")
      yield line
    else
      break
    end
  end
end

THREAD_START = /prio=.*tid=.*/
def each_thread(file)
  while(line = file.gets)
    if (line =~ THREAD_START)
      yield file, line
    elsif (line != "\n")
      break
    end
  end
end

DUMP_START = /^Full thread dump/
def each_thread_dump(file)
  while(line = file.gets)
    if (line =~ DUMP_START)
      yield file
    end
  end
end


METHOD_STACK = /\tat (.*)\n/

graph = {}
root = StackFrame.new("root")
graph["root"] = root

File.open( ARGV[0] ) do |file|
  each_thread_dump(file) do |file|
    each_thread(file) do |file, thread|
      
      prev = nil
      runnable = (thread.index("runnable") != nil)
      servlet = false
      lines = []
      each_stack_line(file) do |line|
        next if line !~ METHOD_STACK
        
        java_code = $1
        next if java_code =~ ELIDE_FRAME
        
        lines << java_code
        servlet = (line =~ STACK_INCLUSION) if !servlet
      end
      
      next if !servlet
      
      lines.each do |java_code|
        frame = graph[java_code]
        if !frame
          frame = StackFrame.new(java_code)
          graph[java_code] = frame
        end
        
        frame.branch(prev) if prev
        frame.runnable_count += 1 if runnable
        prev = frame
        
      end
      
      if prev
        root.branch(prev)
      end
      
    end
  end
end

Marshal.dump(graph, File.open(ARGV[1], "wb"))
