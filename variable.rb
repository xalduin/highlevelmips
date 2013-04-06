require_relative 'type.rb'

class Variable
    attr_reader :type, :ident

    # Can be used in structs for offsets or for s register number
    attr_accessor :num

    def initialize(typename, identity)
        # Ensure that a valid type is being used
        unless Type.include?(typename)
            raise "Invalid type '#{typename}'"
        end
        @ident = identity.to_sym
        @type  = typename
    end
end

class VariableList
    attr :variables

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

    def get(ident)
        return @variables[ident]
    end
end
