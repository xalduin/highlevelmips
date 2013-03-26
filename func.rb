require 'statement.rb'

FUNC_ARGS_REGEXP = /([a-zA-Z]\w*)\s*:\s*([a-zA-Z]+)/

# String * [] -> true/nil
# Returns true on success, nil on failure

# arg_list must be an empty array
# Stores arguments in arg_list in the following format:
# [{:name => String, :type => String}]

def process_args(args, arg_list)
    unless arg_list.empty?
        puts "Arg list must be empty!"
        return nil
    end

    # Array of matches
    arg_defs = args.scan(FUNC_ARGS_REGEXP)

    arg_defs.each do |arg_match|
        name = arg_match[1]
        type = arg_match[2]

        unless valid_type?(type)
            puts "Invalid argument type '#{type}'"
            return nil
        end

        arg_list.add({:name => name, :type => type})
    end

    return true
end

# Process a function call declaration
# Returns nil on failure, true on success
#
# Modifies the global table hash in the following ways:
# [:current_func] is set to the name of the declared function
# [:func][name] is used to store a local table for the function
# [:func_type][name] is used to store return type (String or nil)
# [:func_args][name] stores a list of function args
#
# the local table is initialized as such:
# [:var_index] = 0
# [:instructions] = 0

def process_func_decl(line, match, global_table)
    name = match[1]
    args = match[2]
    result_type = match[9]

    if global_table[:current_func] != nil
        puts "Unable to nest function declarations"
        return nil
    end

    if global_table[:func].has_key?(name)
        puts "Redeclared function: '#{name}'"
        return nil
    end

    if result_type
        unless valid_type?(result_type)
            puts "Invalid return type '#{result_type}'"
            return nil
        end
    end

    local_table = {}
    arg_list = []

    unless process_args(args, arg_list)
        return nil
    end

    # So far so good, store results
    global_table[:current_func] = name
    global_table[:func][name] = local_table
    global_table[:func_type][name] = result_type
    global_table[:func_args][name] = arg_list

    # Initialize variable index to 0 for this new function
    local_table[:var_index] = 0
    local_table[:instructions] = []

    return true
end

# String * match * {} -> true/nil
# Returns true on success, nil on failure

# Checks to ensure that there is a function to be ended by endfunc
#TODO: Ensure that all loops/if statements have been ended
def process_endfunc(line, match, global_table)

    unless global_table[:current_func]
        puts "No matching function found for endfunc statement"
        return nil
    end

    global_table[:current_func] = nil
    return true
end
