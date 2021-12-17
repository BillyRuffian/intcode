
class ProgramCounter  
  def initialize()= @counter = 0

  def inc(amount = 1)= @counter += amount
  def dec(amount = 1)= @counter -= amount
  def set(value)= @counter = value
  def to_i()= @counter
  def to_s()= @counter.to_s
  def to_int()= @counter
  def to_str()= @counter.to_str
end

class Operation
  attr_reader :modes, :memory, :rb

  MODE = {
    position: 0,
    immediate: 1,
    relative: 2
  }
  
  def initialize(opcode)
    @opcode = opcode
    @modes = (opcode / 100).to_s.rjust(arity, '0').chars.reverse.map(&:to_i)
  end
  
  def arity()= 0
  def inspect()= "#{self.class.name}: #{@opcode}"
  def to_s()= self.class.name
  def writes?()= true
  
  def perform(*args)
    #puts "Perform #{self} with #{args.join(',')}"
  end

  def with_memory(memory)
    @memory = memory
    self
  end
  
  def with_relative_base(rb)
    @rb = rb
    self
  end

  def attribute_values(attrs)
    attributes = attrs.clone
    write_location = attributes.pop if writes?

    values = attributes.zip(modes).map { |(value, mode)| read(value, mode) }
    
    if write_location
      write_location = write_location + rb.to_i if modes.last == MODE[:relative]
      values << write_location if writes?
    end
    
    values
  end

  def read(value, mode)
    case mode
    when MODE[:position]
      memory[value]
    when MODE[:immediate]
      value
    when MODE[:relative]
      memory[value + rb.to_i]
    end
  end
  
  def self.fetch(opcode)
    case opcode % 100
    when 1 then Add.new(opcode)
    when 2 then Multiply.new(opcode)
    when 3 then Input.new(opcode)
    when 4 then Output.new(opcode)
    when 5 then JumpIfTrue.new(opcode)
    when 6 then JumpIfFalse.new(opcode)
    when 7 then LessThan.new(opcode)
    when 8 then Equals.new(opcode)
    when 9 then RelativeBaseOffset.new(opcode)
    when 99 then Halt.new(opcode)
    end
  end
end

class ReadOnlyOperation < Operation
  def writes?()= false
end

class JumpOperation < ReadOnlyOperation
  attr_reader :pc 

  def with_program_counter(pc)
    @pc = pc 
    self
  end
end

class Halt < ReadOnlyOperation; end

class Add < Operation
  def arity()= 3
  
  def perform(*args)
    super
    values = attribute_values(args)
    memory.write(values[-1], values[0..-2].inject(:+))
  end
end

class Multiply < Operation
  def arity()= 3
  
  def perform(*args)
    super
    values = attribute_values(args)
    memory.write(values[-1], values[0..-2].inject(:*))
  end
end

class Input < Operation
  def arity()= 1

  def perform(*args)
    super
  
    values = attribute_values(args)
    memory.write(values.first, @input.deliver)
  end

  def with_input(input)
    @input = input
  end
end

class Output < ReadOnlyOperation
  def arity()= 1

  def perform(*args)
    super
    values = attribute_values(args)
    @output.receive(values.first)
  end

  def with_output(output)
    @output = output
  end
end

class JumpIfTrue < JumpOperation
  def arity()= 2

  def perform(*args)
    super
    values = attribute_values(args)
    if !values.first.zero?
      pc.set(values.last)
    else
      pc.inc(arity + 1)
    end
  end
end

class JumpIfFalse < JumpOperation
  def arity()= 2

  def perform(*args)
    super
    values = attribute_values(args)
    if values.first.zero?
      pc.set(values.last) 
    else
      pc.inc(arity + 1)
    end
  end
end

class LessThan < Operation 
  def arity()= 3

  def perform(*args)
    super
    values = attribute_values(args)
    values[0] < values[1] ? memory.write(values[-1], 1) : memory.write(values[-1], 0)
  end
end

class Equals < Operation 
  def arity()= 3

  def perform(*args)
    super
    values = attribute_values(args)
    values[0] == values[1] ? memory.write(values[-1], 1) : memory.write(values[-1], 0)
  end
end

class RelativeBaseOffset < ReadOnlyOperation
  def arity()= 1
  
  def perform(*args)
    super
    values = attribute_values(args)
    rb.inc(values.first)
  end
end


class Memory
  def initialize(program)
    @program = program
  end
  
  def [](*args)
    @program[*args] || 0
  end
  
  def write(location, value)
    @program[location] = value
  end
end

class Intputer
  attr_reader :memory, :pc, :rb, :input, :output

  def initialize(program, input:, output:)
    @pc = ProgramCounter.new
    @rb = ProgramCounter.new
    @input = input 
    @output = output
    @memory = Memory.new(program)
  end
 
  def execute
    while !(op = Operation.fetch(memory[pc])).kind_of? Halt
      if op && op.kind_of?(JumpOperation)
        op.with_memory(memory).with_program_counter(pc).with_relative_base(rb).perform(*memory[pc.to_i + 1, op.arity])
      elsif op
        op.with_memory(memory).with_relative_base(rb)
        if op.is_a? Input
          op.with_input(input)
        elsif op.is_a? Output
          op.with_output(output)
        end
        op.perform(*memory[pc.to_i + 1, op.arity])
        pc.inc(op.arity + 1)
      else
        warn "unknown opcode #{memory[pc]}"
        pc.inc
      end
    end
  end
end

module InputSource
  class StdIn
    def deliver
      print '<< '
      gets.chomp.to_i
    end
  end
end

module OutputSink
  class StdOut
    def receive(value)
      puts ">> #{value}"
    end
  end

  class BufferedOutput
    attr_reader :values 
    
    def initialize
      @values = []
    end

    def receive(value)
      values << value
    end
  end
end



 # pp intputer.memory
 