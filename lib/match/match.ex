defmodule Game.Match do

    # -> {list,confirm_list, confirm_with_robot_list}
    def match(vs_mode_id,list,args) do
        ## 不同的类型游戏调用不同的匹配 
        # Golf.Match.match(vs_mode_id,list,args)
        Game.MatchRoom.MatchProtocol.match(vs_mode_id,list,args)
    end

    
end