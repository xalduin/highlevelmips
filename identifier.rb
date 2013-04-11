class Identifier
    attr_reader :ident, :type

    def initialize(ident, type)
        @ident = ident
        @type = type
    end
end

class IdentifierList
    attr :ident_hash

    def add_ident(ident)
        unless ident.is_a? Identifier
            raise ArgumentError, 'Argument must be an Identifier'
        end

        @ident_hash[ident.ident] = ident
    end

    def get(ident_sym)
        return @ident_hash[ident_sym.to_sym]
    end

    def include?(ident)
        unless ident.is_a? Identifier
            raise ArgumentError, 'Argument must be an Identifier'
        end
    end

    def has_sym?(ident_sym)
        return @ident_hash.has_key?(ident_sym.to_sym)
    end
    
    def initialize
        @ident_hash = {}
    end
end
