class Brainfuck
  
  attr_accessor :raw_code #allow access to the raw code (good for just loading the code file to strip out everything)
  
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
    
    #probably a more ruby-esque way to do this... find all optimizable commands
    #and find how many times they appear in order (sequential commands)
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
      case @opt_code[i]
        when '['
          stop, j = false, 0
          while !(stop) do
            i += 2
            case @opt_code[i]
              when ']'
                stop = (j == 0)
                j -= 1
              when '['
                j + 1
            end
          end
          
          @opt_code[l + 1], @opt_code[i + 1] = i, l
      end
      
      i += 1
    end
    
    #puts @opt_code
  end
  
  #run the bf code
  def interperate
    mem = Array.new(30000, 0)
    ptr, v = 0, 0
    
    i = 0
    while i < @opt_code.length do
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
      
      i += 2
    end
    
  end
  
  private :optimize
end

if __FILE__ == $0 #only run if this is the main file
  bf_file = ARGV[0]
  if bf_file.nil? || bf_file.empty? || bf_file == '-?'
      abort("Usage: ruby brainf*ck.rb hello_world.b")
  end
  
  bf = Brainfuck.new(bf_file)
  bf.interperate
end