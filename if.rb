require_relative 'expression.rb'
require_relative 'statement.rb'
require_relative 'function.rb'

# String * MatchData * Hash * Hash -> true/nil
# true = success, nil = failure
#
# Checks the matched string to ensure it follows the correct if statement
# formula then adds an entry to the instruction list
def process_if(match, func)

    unless func.is_a? Function
        raise "if statement must be used inside a function"
    end

    # Try to process the condition
    expression = match[1]
    value = process_condition(expression, func.var_list)

    instruction = IfInstruction.new(value, func)
    func.add_instruction(instruction)

    return true
end

def process_else(func)
    raise "else statement must be used in a function" unless func.is_a? Function

    instruction = ElseInstruction.new(func)
    func.add_instruction(instruction)
end

def process_endif(func)
    unless func.is_a? Function
        raise "endif statement must be used in a function"
    end

    instruction = EndifInstruction.new(func)
    func.add_instruction(instruction)
end

class IfInstruction
    @@num_stack = []
    @@index = 1
    @@else_hash = {}

    # Accessors for class variables
    def self.index
        @@index
    end
    def self.num_stack
        @@num_stack
    end
    def self.else_hash
        @@else_hash
    end

    attr_reader :expr, :func, :num

    def initialize(expression, func)
        # Assign a unique number for this if statement
        @num = @@index
        @@index += 1
        @@num_stack.push(@num)

        @expr = expression
        @func = func
    end

    def render
        label = "#{@func.ident}_"
        if @@else_hash.has_key? @num
            label += "else_#{@num}"
        else
            label += "endif_#{@num}"
        end

        return generate_branch_negation(@expr, label, @func.var_list)
    end
end

class ElseInstruction
    attr :func, :num

    def initialize(func)
        @func = func
        @num = IfInstruction.num_stack[-1]
        raise "No matching if statement for else" if @num == nil

        else_hash[@num] = true
    end

    def render
        label = "#{@func.ident}_else_#{@num}"
        return [generate_label(label)]
    end
end

class EndifInstruction
    attr :func, :num

    def initialize(func)
        @func = func
        @num = IfInstruction.num_stack.pop
        raise "No matching if for endif" if @num == nil
    end

    def render
        label = "#{@func.ident}_endif_#{@num}"
        return [generate_label(label)]
    end
end
