defmodule Game.Global do 
    require Logger    
    @doc """
            全局模块
        """
    @match_room_module "Elixir.Game.MatchRoom"
    
    # -> string 
    def get_match_room_name(vs_mode_id) do 
        name=String.to_atom(@match_room_module <>"#{inspect vs_mode_id}")
        Logger.error("name=#{inspect name}")
        name
    end

    # -> pid | nil 
    def get_match_room_pid(vs_mode_id) do 
        case :global.whereis_name(get_match_room_name(vs_mode_id)) do 
                :undefined -> 
                    nil
                pid -> 
                    pid 
        end
    end

    # Game.Global.get_all_room_user_cnt()
    # -> [{id,integer}] | {:error,reason}
    def get_all_room_user_cnt() do 
        vs_mode_ids=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14]
        List.foldr(vs_mode_ids,[],fn(x,acc)->
                        [get_room_user_cnt(x)|acc]
                     end)
    end

    # Game.Global.get_room_user_cnt(0)
    # -> [{id,integer}] | {:error,reason}
    def get_room_user_cnt(id) do 
        room_pid= get_match_room_pid(id)
          case room_pid do 
            nil -> 
                {id,0}
            _ -> 
                try do 
                    {id,GenServer.call(room_pid,{:get_room_user_cnt})}
                rescue
                    RuntimeError -> 
                        {id,0}
                end
          end
    end



end