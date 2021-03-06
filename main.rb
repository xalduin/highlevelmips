require_relative 'statement.rb'
require_relative 'process_variable.rb'
require_relative 'func.rb'
require_relative 'loop.rb'
require_relative 'if.rb'
require_relative 'func_call.rb'

require_relative 'func_gen.rb'
require_relative 'asm_func.rb'

require_relative 'types.rb'
require_relative 'string_table.rb'

def process_line(line, blocks, func_list, type_table)
    # Remove leading whitespace, comments and extra spaces
    line = line.strip
    line.gsub!(/#.*/, '')
    line.gsub!(/  /, ' ')
    line.gsub!(/\s*,\s*/, ',')

    block = blocks[-1]

    match = line.match(S_VAR_DECL)
    if match
        return process_var(match, block, type_table)
    end

    match = line.match(S_CONST_DECL)
    if match
        raise "Unsupported feature"
        #return process_const_decl(line, match, table, local_table)
    end

    match = line.match(B_FUNC_DECL)
    if match
        func = process_func_decl(match, func_list, block, type_table)
        blocks.push(func)
        return true
    end

    match = line.match(B_ENDFUNC)
    if match
        process_endfunc(block)
        blocks.pop
        return true
    end

    match = line.match(B_IF_DECL)
    if match
        return process_if(match, block, type_table)
    end

    match = line.match(B_ELSE_DECL)
    if match
        return process_else(block)
    end

    match = line.match(B_ENDIF)
    if match
        return process_endif(block)
    end

    match = line.match(B_LOOP_DECL)
    if match
        return process_loop(block)
    end

    match = line.match(B_EXITWHEN)
    if match
        return process_exitwhen(match, block, type_table)
    end

    match = line.match(B_ENDLOOP)
    if match
        return process_endloop(block)
    end

    match = line.match(S_FUNC_CALL)
    if match
        return process_func_call(match, block, func_list, type_table)
    end

    match = line.match(S_SET_VAR)
    if match
        return process_set(match, block, type_table)
    end

    match = line.match(S_RETURN)
    if match
        return process_return(match, block, type_table)
    end

    if line.match(/^\s*$/)
        return true
    end

    raise "Unrecognized expression"
end
    
def parse_input(input_file)
    text = File.open(input_file).read
    text.gsub!(/\r\n?/, "\n")

    blocks = []
    type_table = new_default_type_table()
    func_list = FunctionList.new
    init_asm_functions(func_list)

    line_number = 1
    text.each_line do |line|

        begin
            process_line(line, blocks, func_list, type_table)
        rescue RuntimeError => e
            puts "#{e.message}" 
            puts "Line #{line_number}: #{line}"
            puts "Failed to parse file"
            return nil
        rescue => e
            puts "Line #{line_number}: #{line}"
            puts "#{e.message}"
            print e.backtrace.take(5).join("\n")
            puts ""
            return nil
        end

        line_number += 1
    end

    return func_list
end

def create_asm(func_list, output_file)
    result = []
    File.open(output_file, "w") do |file|
        result = generate_program(func_list)
        result.each do |line|
            file << line + "\n"
        end
    end

    return true
end

def run_test
    func_list = parse_input('input.hlm')
    if func_list != nil
        create_asm(func_list, 'output.asm')
    end
end

if ARGV.size == 0
    run_test
elsif ARGV.size > 1
    puts "Usage: ruby main.rb <input file>"
else

    func_list = parse_input(ARGV[0])
    if func_list != nil
        create_asm(func_list, ARGV[0] + ".asm")
    end
end
