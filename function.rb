require_relative 'type.rb'
require_relative 'identifier.rb'
require_relative 'variable.rb'

class Function < Identifier
    attr_reader :return_type, :arg_list, :var_list, :instr_list
    attr :ident_list
    attr :local_register_stack, :temp_register_stack

    def initialize(ident, return_type, arg_list, func_list)

        # Type checking
        unless arg_list.is_a? Array
            raise "arg_list must be an Array"
        end

        if return_type != nil
            @return_type = return_type.to_sym
            unless Type.include? @return_type
                raise "Unknown return type '#{return_type}'"
            end
        else
            @return_type = nil
        end

        @ident = ident.to_sym
        @type = @return_type

        @arg_list = arg_list
        @var_list = VariableList.new()
        @instr_list = []

        @local_register_stack = (0..8).to_a.reverse!
        @temp_register_stack  = (0..8).to_a.reverse!

        @ident_list = IdentifierList.new
        func_list.each do |func|
            @ident_list.add_ident(func)
        end
        @ident_list.add_ident(self)

        arg_list.each do |var|
            add_variable(var)
        end
    end

    def add_variable(var)
        register = @local_register_stack.pop
        raise "Max local count reached" if register == nil

        var.num = register
        @var_list.add(var)
        @ident_list.add_ident(var)
    end

    def add_instruction(instr)
        @instr_list.push instr
    end

    def ident_list
        return @ident_list
    end
end

class FunctionList
    attr_reader :func_hash

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


