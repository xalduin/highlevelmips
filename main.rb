load 'statement.rb'
load 'variable.rb'
load 'func.rb'
load 'loop.rb'

LOCAL_COUNT = 8

def valid_type?(type)
    return VAR_TYPES.include?(type)
end

def process_line(line, table)
    # Remove leading whitespace, comments and extra spaces
    line.strip!
    line.gsub!(/#.*/, '')
    line.gsub!(/  /, ' ')
    line.gsub!(/ *, */, ',')

    local_table = nil
    func_name = table[:current_func]
    if func_name
        local_table = table[:func][func_name]
    end

    match = line.match(S_VAR_DECL)
    if match
        return process_var(line, match, table, local_table)
    end

    match = line.match(S_CONST_DECL)
    if match
        return process_const_decl(line, match, table, local_table)
    end

    match = line.match(B_FUNC_DECL)
    if match
        return process_func_decl(line, match, table)
    end

    match = line.match(B_ENDFUNC)
    if match
        return process_endfunc(line, match, table)
    end

    match = line.match(B_IF_DECL)
    if match
        return process_if(line, match, table, local_table)
    end

    match = line.match(B_LOOP_DECL)
    if match
        return process_loop(line, match, table, local_table)
    end

    match = line.match(B_EXITWHEN)
    if match
        return process_exitwhen(line, match, table, local_table)
    end

    match = line.match(B_ENDLOOP)
    if match
        return process_endloop(line, match, table, local_table)
    end

    if line.match(/^\s*$/)
        return true
    end

    puts "Unrecognized expression"
    return nil
end
    
def run_program()
    text = File.open("input.hlm").read
    text.gsub!(/\r\n?/, "\n")

    table = {}

    line_number = 1
    text.each_line do |line|
        result = process_line(line, table)
        
        if result == nil
            puts "Line #{line_number}: #{line}\n"
            puts "Failed to parse file"
            break
        end

        line_number += 1
    end
    puts "Finished"

    return table
end

#run_program
#puts "Finished"
