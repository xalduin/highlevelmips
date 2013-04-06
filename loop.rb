require_relative 'expression.rb'
require_relative 'function.rb'
require_relative 'instruction_gen.rb'

# String * MatchData * {} * {} -> true/nil
# Process a loop declaration
# Asserts that the loop is declared inside a function

def process_loop(func)
    instruction = LoopInstruction.new(func)
    func.add_instruction(instruction)
    return true
end

#TODO: Ensure that all loops have been ended before ending a function
# Function -> true
# true on success, exception raised on failure

def process_endloop(func)
    instruction = EndloopInstruction.new(func)
    func.add_instruction(instruction)
    return true
end
    
# String * MatchData * {} * {} -> True/nil
# true on success, nil on failure
#
# Adds an additional instruction on success
# Instruction format:
# :type => exitwhen
# :index => loop index
# :value => value
def process_exitwhen(match, func)
    expression = match[1]
    value = process_condition(expression, func.var_list)

    instruction = ExitwhenInstruction.new(value, func)
    func.add_instruction(instruction)

    return true
end

class LoopInstruction
    @@num_stack = []
    @@index = 1

    # Accessors for class variables
    def self.index
        @@index
    end
    def self.num_stack
        num_stack
    end

    attr_reader :func, :num

    def initialize(func)
        # Assign a unique number for this if statement
        @num = @@index
        @@index += 1
        @@num_stack.push(@num)

        @func = func
    end

    def render
        label = "#{@func.ident}_loop_#{@num}"
        return [generate_label(label)]
    end
end

class EndloopInstruction
    attr :func, :num

    def initialize(func)
        @func = func
        @num = LoopInstruction.num_stack.pop
        raise "No matching loop for endloop" if @num == nil
    end

    def render
        loop_label = "#{@func.ident}_loop_#{@num}"
        end_label  = "#{@func.ident}_endloop_#{@num}"
        result = []

        result<< generate_j(loop_label)
        result<< generate_label(end_label)
        return result
    end
end

class ExitwhenInstruction
    attr :func, :num, :expr

    def initialize(expression, func)
        @expr = expression
        @func = func
        @num = LoopInstruction.num_stack.pop
        raise "No matching loop for endloop" if @num == nil
    end

    def render
        end_label = "#{@func.ident}_endloop_#{@num}"
        return generate_branch(@expr, end_label, @func.var_list)
    end
end
