require_relative 'type.rb'
require_relative 'Identifier.rb'

class Variable < Identifier
    attr_reader :array

    # Can be used in structs for offsets or for s register number
    attr_accessor :num, :register

    def initialize(typename, identifier, is_array)
        identifier = identifier.to_sym
        typename = typename.to_sym
        super(identifier, typename)

        # Ensure that a valid type is being used
        unless Type.include?(typename)
            raise "Invalid type '#{typename}'"
        end

        @ident = identifier
        @type  = typename
        @array = is_array

        @num = nil
        @register = nil
    end

    def is_array?
        return @array
    end
end

class VariableList
    attr_reader :variables

    def initialize()
        @variables = {}
    end

    # Variable -> true/false
    # Adds the variable to this list unless it has previously been added
    #
    # Param:
    #   var - The variable that is to be added to this list
    #
    # Returns:
    #   true  - successfully added the Variable
    #   false - Variable is already in this list
    def add(var)
        unless var.is_a? Variable
            raise "Internal: Argument must be Variable '#{var}'"
        end

        if @variables.has_key? var.ident
            return false
        end

        @variables[var.ident] = var
        return true
    end

    # Symbol -> true/false
    # 
    # Param:
    #   ident - the identifier (name) of the Variable to check for
    #
    # Returns:
    #   true if this list contains the specified identifier, false otherwise
    def include?(ident)
        return @variables.has_key?(ident.to_sym)
    end
    def has_ident?(ident)
        return @variables.has_key?(ident.to_sym)
    end

    def get(ident)
        return @variables[ident.to_sym]
    end

    def length
        return @variables.length
    end
    def size
        return @variables.size
    end
end
