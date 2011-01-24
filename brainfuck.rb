class Brainfuck
  
  attr_accessor :raw_code 
  attr_accessor :opt_code
  
  def initialize(bf_file)
    @raw_code = '' #holds the raw bf code
    @opt_code = [] #holds the optimized bf code
    
    #open brainfuck file, and strip out invalid characters
    begin
      File.open(bf_file, "r") { |f| @raw_code = f.read.gsub(/[^<>+\-,.\[\]]/, '')}
    rescue
      abort("Check your filename.")
    end
    
    optimize
  end

  #optimize code, convert it into a array with commands followed by values
  #ie, instead of +++++, which is +1 +1 +1 +1 +1, just make it +5
  def optimize
    if @raw_code.nil? || @raw_code.length == 0
      abort("Bad code.")
    end
    
    #bf commands that can be optimized
    opt_comms = ['<', '>', '+', '-']
    
    #special command for the bf nil operator.  '[-]' will always zero out the value
    #at the pointer, so shortcut it
    @raw_code = @raw_code.gsub(/\[-\]/, '=')
    
    #tranform the bf script into an optimized array, ie
    # "++++++++++[>+++++++>++++++++++>+++>+<<<<-][-]" becomes
    # [ '+', 10, '[', X, '>', 1, '+', 7, '>', 1, '+', 10, '>', 1, '+', 3, '>', 1, '+',1, '<', 4, '-', 1,']', X, '=', 0 ]
    i = 0
    while i < @raw_code.length do
      c, t = @raw_code[i, 1], @raw_code[i + 1, 1]
      j = 0
      
      if !(opt_comms.index(c).nil?) && t == c
        while t == c do
          j += 1
          i += 1
          t = @raw_code[i, 1]
        end
        i -= 1
      else
        j += 1
      end
      
      @opt_code.push(c).push(j)
      
      i += 1
    end
    
    stop = false
    i, j, l = 0, 0, 0
    
    #optimize bf loops, find the corresponding ']' to '[', so we can immediately
    #jump to that point instead of constantly having to look it up during run-time
    while i < @opt_code.length do
      l = i
      if @opt_code[i] == '['
        stop, j = false, 0
        until stop do
          i += 2
          case @opt_code[i]
            when ']'
              stop = (j == 0)
              j -= 1
            when '['
              j += 1
          end
        end
        
        @opt_code[l + 1], @opt_code[i + 1] = i, l
      end
      
      i = l
      i += 2
    end
  end
  
  #run the bf code
  def interperate
  
    cap = 1000000 #maximum number of 'operations' allowed
    ops = 0
  
    mem = Array.new(30000, 0)
    ptr, v = 0, 0
    
    begin
      i = 0
      while i < @opt_code.length && ops < cap do
        case @opt_code[i]
          when '+' #increment that value @ pointer
            mem[ptr] += @opt_code[i + 1]
          when '-' #decrement the value @ pointer
            mem[ptr] -= @opt_code[i + 1]
          when '=' #nil (zero-out) the value @ pointer
            mem[ptr] = 0
          when ',' #read in
            #mem[ptr] = get_character.bytes
          when '.' #write out value (as char) at the pointer
            print mem[ptr].chr
          when '>' #increment the pointer
            ptr += @opt_code[i + 1]
          when '<' #decrement the pointer
            ptr -= @opt_code[i + 1]
          when '[' #begin loop
            i = (mem[ptr] == 0) ? @opt_code[i + 1] : i
          when ']' #end loop
            i = (mem[ptr] != 0) ? @opt_code[i + 1] : i
        end
        
        #ops += 1
        i += 2
      end
    rescue
      puts ""
    end
  end
  
  private :optimize
end

if __FILE__ == $0
  bf_file = ARGV[0]
  if bf_file.nil? || bf_file.empty? || bf_file == '-?'
      abort("Usage: ruby brainfuck.rb hello_world.b [-v]")
  end
  
  bf = Brainfuck.new(bf_file)
  
  if ARGV[1] == '-v'
    puts "Raw:\n#{bf.raw_code}\n\nOptimized:\n#{bf.opt_code.to_s}\n\n--BEGIN--"
  end
  
  bf.interperate
  
  if ARGV[1] == '-v'
    puts '--END--'
  end
end

















