require_relative 'instructions.rb'
require_relative 'function.rb'

class AssemblyFunction < Function
    def initialize(ident, return_type, arg_list)
        unless return_type == nil
            @type = return_type.to_sym
        else
            @type = nil
        end

        @ident = ident.to_sym
        @arg_list = arg_list
    end
end

PRINT_INT = 0
PRINT_STR = 4
READ_INT = 5

ARG_REG = RS_ARG + "0"
SYS_REG = RS_RETURN + "0"

class PrintIntFunction < AssemblyFunction
    IDENT = :print_int

    def initialize
        arg_list = [Variable.new(:word, :__arg, false) ]
        super(IDENT, nil, arg_list)
    end

    def render
        result = []

        result<< generate_li(SYS_REG, PRINT_INT)
        result<< generate_syscall()
        return result
    end
end

class PrintStringFunction < AssemblyFunction
    IDENT = :print_string

    def initialize
        arg_list = [ Variable.new(:byte, :__arg, true) ]
        super(IDENT, nil, arg_list)
    end

    def render
        result = []

        result<< generate_li(SYS_REG, PRINT_STR)
        result<< generate_syscall()
        return result
    end
end

class ReadIntFunction < AssemblyFunction
    IDENT = :read_int

    def initialize
        super(IDENT, :word, [])
    end

    def render
        result = []

        result<< generate_li(SYS_REG, READ_INT)
        result<< generate_syscall()
        return result
    end
end

def init_asm_functions(func_list)
    func_list.add(PrintIntFunction.new)
    func_list.add(PrintStringFunction.new)
    func_list.add(ReadIntFunction.new)
end
