class ProgramCounter  
  def initialize()= @counter = 0

  def inc(amount = 1)= @counter += amount
  def dec(amount = 1)= @counter -= amount
  def to_i()= @counter
  def to_s()= @counter.to_s
  def to_int()= @counter
  def to_str()= @counter.to_str
end

class Operation
  attr_reader :memory
  
  def initialize(memory)
    @memory = memory
  end
  
  def arity()= 0
  def inspect()= self.class.name
  def perform(*args)
    puts "Perform #{self} with #{args.join(',')}"
  end
  
  def self.fetch(opcode)
    case opcode
    when 1 then Add
    when 2 then Multiply
    when 99 then Halt
    end
  end
end



class Halt < Operation; end

class Add < Operation
  def arity()= 3
  
  def perform(a, b, result_location)
    memory.write(result_location, memory[a] + memory[b])
  end
end

class Multiply < Operation
  def arity()= 3
  
  def perform(a, b, result_location)
    memory.write(result_location, memory[a] * memory[b])
  end
end

class Memory
  def initialize(program)
    @program = program
  end
  
  def [](*args)
    @program[*args]
  end
  
  def write(location, value)
    @program[location] = value
  end
end

class Intputer
  attr_reader :memory, :pc

  def initialize(program)
    @pc = ProgramCounter.new
    @memory = Memory.new(program)
  end
 
  def execute
    while (op_class = Operation.fetch(memory[pc])) != Halt
    
      pp memory
      if op_class
        op = op_class.new(memory)
        op.perform(*memory[pc.to_i + 1, op.arity])
        pc.inc(op.arity + 1)
      else
        pc.inc
      end
    end
    pp memory
  end
 
end

program = File.read('input.txt').split(',').map(&:to_i)
 
Intputer.new(program).execute
 
 