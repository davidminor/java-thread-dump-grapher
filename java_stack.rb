
class Branch
  attr_accessor :frame, :count
  
  def initialize(frame)
    @frame = frame
    @count = 0
  end
end

class StackFrame
  attr_accessor :java_code, :count, :runnable_count, :branches
  
  def initialize(java_code)
    @java_code = java_code
    @count = 0
    @runnable_count = 0
    @branches = {}
  end
  
  def branch(frame)
    branch = @branches[frame]
    if !branch
      branch = Branch.new(frame)
      @branches[frame] = branch
    end
    
    branch.count += 1
    frame.count += 1
  end
end
