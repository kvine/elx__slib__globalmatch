defmodule  Random.Util do

    @doc """
        set random seed
    """
    @spec rand_seed() :: :ok
    def rand_seed() do 
        case :erlang.get(:random_seed) do
                :undefined -> 
                    :random.seed(:os.timestamp())
                    seed={:random.uniform(99999),:random.uniform(99999),:random.uniform(99999)}
                    :random.seed(seed)
                    :ok
                _ ->
                    :ok
        end
    end

    @doc """
        Generate a 48-bit random id (0 excepted)
    """
    @spec rand_id() :: pos_integer
    def rand_id do
        rand_id(1)
    end


    @doc """
        Generate a 48-bit random id (won't less than Min)
    """
    @spec rand_id(min :: pos_integer) :: pos_integer
    def rand_id(min) do
        rand_id(min,48)
    end


    @doc """
        Generate a random id (won't less than Min)
    """
    @spec rand_id(min :: pos_integer, bits :: 1..64) :: pos_integer 
    def rand_id(min,bits) when is_integer(min) and min >=0 and is_integer(bits) and bits >=1 and bits <= 64 do 
        bytes= div((bits + 7) , 8)
        <<result :: size(bits), _t :: bitstring>> =  :crypto.strong_rand_bytes(bytes)
        case result do 
             nil -> 
                rand_id(min,bits)
             _ ->
                case result >= min do
                        true -> result
                        false -> rand_id(min, bits)
                end
        end
    end


    @doc """
       Generate a random token: [A-Za-z0-9+/]{16}
    """
    @spec rand_token() :: String.t
    def rand_token() do
        bytes=:crypto.strong_rand_bytes(12)
        :base64.encode(bytes)
    end

    @doc """
        return a num between min(include)-max(include)
    """
    @spec rand_range(min:: integer, max:: integer) :: integer | {:error,:bad_arg}
    def rand_range(min, max) do 
        case min > max do 
            true -> 
                {:error,:bad_arg}
            false ->
                min+:random.uniform(max-min+1)-1
        end
    end

    @doc """
        get id by probability
        locid is the elem's loc in the probability list
        probability list: [{id,probability}]
        ect:
            get_locid_by_probs([{0,0.5},{1,0.2},{2,0.3}])
            return:  0|1|2
           
    """
    def get_locid_by_probs(probs) do 
         tgt= :random.uniform()
         get_locid_by_probs_1(0,probs,tgt,0,0)
    end


    defp get_locid_by_probs_1(sum,[],tgt,loc,default_id) do 
            default_id
    end

    defp get_locid_by_probs_1(sum,[h|t],tgt,loc,default_id) do 
            sum = sum + h
            case sum >= tgt do 
                    true -> 
                        loc
                    false -> 
                        get_locid_by_probs_1(sum,t,tgt,loc+1,default_id)
            end
    end

end