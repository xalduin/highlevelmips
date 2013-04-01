require_relative 'expression.rb'
require_relative 'statement.rb'


# String * MatchData * Hash * Hash -> true/nil
# true = success, nil = failure
#
# Checks the matched string to ensure it follows the correct if statement
# formula then adds an entry to the instruction list
#
# Local table adjustments:
# [:if_index] is created or incremented if it already exists
# [:if_stack] has the new value of :if_index appended to it
# [:if_has_else][#] is set to false
#
# Instruction list addition:
# {:type => :if, :value => expression value}
def process_if(line, match, global_table, local_table)
    unless global_table[:current_func]
        puts "If statements must be used inside functions"
        return nil
    end

    # If there is no table entry for index/stack, create them
    if local_table[:if_index] == nil
        local_table[:if_index] = 0
    end
    if local_table[:if_stack] == nil
        local_table[:if_stack] = []
    end
    if local_table[:if_has_else] == nil
        local_table[:if_has_else] = {}
    end

    # Try to process the condition
    expression = match[1]
    value = process_condition(expression, local_table)

    # Expression error found
    if value == nil
        return nil
    end

    # Get current index and push it on to stack
    if_index = local_table[:if_index]
    if_stack = local_table[:if_stack]

    if_index += 1
    if_stack.push(if_index)
    local_table[:if_index] = if_index
    local_table[:if_has_else][if_index] = false

    # Add the instruction to the list
    instruction_list = local_table[:instructions]
    instruction_list<< {:type  => :if,
                        :index => if_index,
                        :value => value
    }

    return true
end

def process_else(line, match, global_table, local_table)
    unless global_table[:current_func]
        puts "Else statement must be used inside a function"
        return nil
    end

    if_stack = local_table[:if_stack]

    if if_stack == nil || if_stack.empty?
        puts "Else statement must be used after an if statement"
        return nil
    end

    if_index = if_stack[-1]

    if local_table[:if_has_else][if_index] == true
        puts "Can only use one else statement per if statement"
        return nil
    end

    local_table[:if_has_else][if_index] = true

    instruction_list = local_table[:instructions]
    instruction_list<< {:type  => :else,
                        :index => if_index
    }
end

def process_endif(line, match, global_table, local_table)
    unless global_table[:current_func]
        puts "Endif statement must be used inside a function"
        return nil
    end

    if_stack = local_table[:if_stack]

    if if_stack == nil || if_stack.empty?
        puts "endif statement must be used after an if statement"
        return nil
    end

    if_index = if_stack.pop

    instruction_list = local_table[:instructions]
    instruction_list<< {:type  => :endif,
                        :index => if_index
    }
end
    
   






