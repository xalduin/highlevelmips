require_relative 'type.rb'
require_relative 'variable.rb'

class Function
    attr_reader :ident, :return_type, :arg_list, :var_list, :instr_list
    attr :local_register_stack, :temp_register_stack

    def initialize(ident, return_type, arg_list)
        # Type checking
        unless arg_list.is_a? Array
            raise "arg_list must be an Array"
        end

        return_type = return_type.to_sym
        unless Type.include? return_type
            raise "Unknown return type '#{return_type}'"
        end

        @ident = ident.to_sym
        @return_type = return_type
        @arg_list = arg_list
        @var_list = VariableList.new()
        @instr_list = []

        @local_register_stack = (0..8).to_a.reverse!
        @temp_register_stack  = (0..8).to_a.reverse!

        arg_list.each do |var|
            add_variable(var)
        end
    end

    def add_variable(var)
        register = @local_register_stack.pop
        raise "Max local count reached" if register == nil

        var.num = register
        @var_list.add(var)
    end

    def add_instruction(instr)
        @instr_list.push instr
    end
end

class FunctionList
    attr :func_hash

    def initialize
        @func_hash = {}
    end

    def add(func)
        return false if @func_hash.has_key? func
        @func_hash[func.ident] = func
        return true
    end

    def include?(func)
        return @func_hash.has_key? func.ident
    end
    def has_ident?(func_ident)
        return @func_hash.has_key? func_ident.to_sym
    end

    def get_ident(func_ident)
        return @func_hash[func_ident.to_sym]
    end

    def each
        @func_hash.each_value do |value|
            yield value
        end
    end
end


