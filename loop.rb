require 'expression.rb'

# String * MatchData * {} * {} -> true/nil
# Process a loop declaration
# Asserts that the loop is declared inside a function
#
# local_table adjustments:
# [:loop_index] is incremented
# [:loop_stack] has the last value of :loop_index appended to it
#
# instruction_list addition:
# {:type => :loop, :index => loop #}
def process_loop(line, match, global_table, local_table)

    unless global_table[:current_func]
        puts "Loops must be used inside functions"
        return nil
    end


    loop_index = local_table[:loop_index]
    loop_stack = local_table[:loop_stack]

    if loop_index == nil or loop_stack == nil
        puts "Null loop stack?"
        return nil
    end

    loop_index += 1
    loop_stack << loop_index
    local_table[:loop_index] = loop_index
    
    instruction_list = local_table[:instructions]
    instruction_list<< {:type => :loop, :index => loop_index}

    return true
end

#TODO: Ensure that all loops have been ended before ending a function
# String * MatchData * {} * {} -> True/nil
# true on success, nil on failure
#
# Post conditions:
# loop_stack has its last element removed
# instruction list has an endloop element added
def process_endloop(line, match, global_table, local_table)
    unless global_table[:current_func]
        puts "Must end a loop inside a function"
        return nil
    end

    loop_stack = local_table[:loop_stack]

    if loop_stack == nil
        puts "Null loop stack"
        return nil
    end
        
    if loop_stack.empty?
        puts "A loop must be declared before it can be ended"
        return nil
    end

    loop_index = loop_stack.slice!(-1)

    instruction_list = local_table[:instructions]
    instruction_list<< {:type => :endloop, :index => loop_index}

    return true
end
    
# String * MatchData * {} * {} -> True/nil
# true on success, nil on failure
#
# Adds an additional instruction on success
def process_exitwhen(line, match, global_table, local_table)
    unless global_table and local_table
        puts "exitwhen must be used inside a function"
        return nil
    end

    loop_stack = local_table[:loop_stack]

    if loop_stack == nil
        puts "exitwhen: Null loop stack"
        return nil
    end

    if loop_stack.empty?
        puts "Must use exitwhen within a loop"
        return nil
    end

    expression = match[1]
    value = process_condition(expression)

    if value == nil
        return nil
    end

    loop_index = loop_stack[-1]
    instruction_list = local_table[:instructions]
    instruction_list<< {:type  => :exitwhen,
                        :index => loop_index,
                        :value => value
    }

    return true
end
