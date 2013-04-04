module Type
    BASE_TYPES = [:word, :half, :byte]
    BASE_CAST = {
        :word => [:half, :byte],
        :half => [:word, :byte],
        :byte => [:word, :half]
    }

    @@defined_types = {
        :word => [:half, :byte],
        :half => [:word, :byte],
        :byte => [:word, :half],
        :word_array => [],
        :half_array => [],
        :byte_array => []
    }

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
    def Type.add(type_sym)
        unless @@defined_types.has_key? type_sym
            @@defined_types[type_sym] = []
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
        type_entry = @@defined_types[type1_sym]

        unless type_entry != nil && include?(type2_sym)
            return false
        end

        type_entry<< type2_sym
        return true
    end

    # Symbol -> true/false
    # Params:
    #   type_sym - symbol referring to a type
    #
    # Returns:
    #   true  - type has been defined
    #   false - type has not been defined
    def Type.include?(type_sym)
        return @@defined_types.has_key? type_sym
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
        type_entry = @@defined_types[type1_sym]

        if type_entry == nil
            return nil
        end

        return type_entry.include? type2_sym
    end

    # Initializes the Type module
    def Type.init()
        BASE_TYPES.each do |type|
            add(type)
        end
        BASE_CAST.each_pair do |type, cast_list|
            cast_list.each do |cast_type|
                add_castable(type, cast_type)
            end
        end
        return nil
    end
end

