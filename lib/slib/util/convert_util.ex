defmodule  Convert.Util do

    @doc """
        convert binary to integer
    """
    # -> integer | {error,reason}
    def b2i(binary) do 
        case is_binary(binary) do 
                true -> 
                    :erlang.binary_to_integer(binary)
                false -> 
                    :erlang.error(:badarg,[binary])
        end
    end
    # -> integer 
    def b2i!(binary) do 
        :erlang.binary_to_integer(binary)
    end

    

    @doc """
        convert binary to integer
    """
    # -> integer | {error,reason}
    def b2f(binary) do 
        case is_binary(binary) do 
                true -> 
                    :erlang.binary_to_float(binary)
                false -> 
                    :erlang.error(:badarg,[binary])
        end
    end
    # -> integer 
    def b2f!(binary) do 
        :erlang.binary_to_float(binary)
    end

end