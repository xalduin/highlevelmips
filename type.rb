module Type

    BASE_TYPES = {
        :word => 4,
        :half => 2,
        :byte => 1,
        :word_array => 4,
        :half_array => 4,
        :byte_array => 4
    }
    BASE_CAST = {
        :word => [:half, :byte],
        :half => [:word, :byte],
        :byte => [:word, :half],
        :const => [:word, :half, :byte]
    }

    @@defined_types = {}
    @@init = false

    class TypeInfo
        attr_reader :ident, :size, :cast_list

        def add_castable(ident)
            ident = ident.to_sym
            if cast_list.include? ident
                return false
            end
            cast_list<< ident.to_sym
            return true
        end

        def castable?(ident)
            return (@ident == ident) || cast_list.include?(ident)
        end

        def initialize(ident, size, cast_list: [])
            @ident = ident.to_sym

            raise "Internal: Invalid size #{size}" if size <= 0
            @size = size

            @cast_list = cast_list
        end
    end

    # Symbol * Symbol -> true/false
    # Adds the given type symbol to the list of valid types unless it was
    # previously added
    #
    # Param:
    #   type_sym - symbol representing type to be added to list
    #
    # Returns:
    #   true - type added
    #   false - type already exists, not added
    def Type.add(type_sym, size)
        unless @@defined_types.has_key? type_sym
            @@defined_types[type_sym] = TypeInfo.new(type_sym, size)
            return true
        end
        return false
    end

    # Symbol * Symbol -> true/false
    # Establishes the ability to cast type1 to type2
    #
    # Params:
    #   type1_sym - symbol representing type1
    #   type2_sym - symbol representing type2
    #
    # Returns:
    #   true - established ability to cast type1 to type 2
    #   false - failed, one of the types not defined
    def Type.add_castable(type1_sym, type2_sym)
        type_info = @@defined_types[type1_sym]

        unless type_info != nil && include?(type2_sym)
            return false
        end

        return type_info.add_castable(type2_sym)
    end

    # Symbol -> true/false
    # Params:
    #   type_sym - symbol referring to a type
    #
    # Returns:
    #   true  - type has been defined
    #   false - type has not been defined
    def Type.include?(type_sym)
        return @@defined_types.has_key? type_sym.to_sym
    end

    # Symbol * Symbol -> true/false/nil
    # Params:
    #   type1_sym - symbol referring to first type
    #   type2_sym - symbol referring to second type
    #
    # Returns:
    #   true  - type1 can be cast to type2
    #   false - type1 cannot be cast to type2
    #   nil   - type1 is undefined
    def Type.castable?(type1_sym, type2_sym)
        type_info = @@defined_types[type1_sym]

        if type_info == nil
            return nil
        end

        return type_info.castable? type2_sym
    end

    # Symbol -> Integer/nil
    # Param:
    #   type_sym - symbol referring to type
    # Returns:
    #   size of the specified type or
    #   nil if type isn't defined
    def Type.size(type_sym)
        type_info = @@defined_types[type_sym.to_sym]

        if type_info == nil
            return nil
        end

        return type_info.size
    end

    # Initializes the Type module
    def Type.init()
        if @@init == true
            return
        end
        @@init = true

        BASE_TYPES.each_pair do |type, size|
            add(type, size)
        end
        BASE_CAST.each_pair do |type, cast_list|
            cast_list.each do |cast_type|
                add_castable(type, cast_type)
            end
        end
        return nil
    end
end

Type.init
