class Identifier
    attr_reader :ident, :type

    def initialize(identity, type)
        @ident = identity
        @type = type
    end
end

class IdentifierList
    attr :ident_hash

    def add_ident(ident)
        unless ident.is_a? Identity
            raise ArgumentError, 'Argument must be an Identity'
        end

        @ident_hash[ident.ident] = ident
    end

    def get(ident_sym)
        return @ident_hash[ident_sym.to_sym]
    end

    def include?(ident)
        unless ident.is_a? Identity
            raise ArgumentError, 'Argument must be an Identity'
        end
    end

    def has_sym?(ident_sym)
        return @ident_hash.has_key?(ident_sym.to_sym)
    end
end
