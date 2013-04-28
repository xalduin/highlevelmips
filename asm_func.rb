require_relative 'types.rb'
require_relative 'instructions.rb'
require_relative 'function.rb'

class AssemblyFunction < Function
    def initialize(ident, return_type, arg_list)
        @type = return_type
        @ident = ident.to_sym
        @arg_list = arg_list
    end
end

PRINT_INT = 1
PRINT_STR = 4
READ_INT = 5

ARG_REG = RS_ARG + "0"
SYS_REG = RS_RETURN + "0"

class PrintIntFunction < AssemblyFunction
    IDENT = :print_int

    def initialize
        arg_list = [Variable.new(WORD_TYPE, :__arg) ]
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
        arg_list = [ Variable.new(ArrayType.new(BYTE_TYPE), :__arg) ]
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
        super(IDENT, WORD_TYPE, [])
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
