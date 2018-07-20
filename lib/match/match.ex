defmodule Game.Global.Match do

    # -> {list,confirm_list, confirm_with_robot_list}
    def match(vs_mode_id,list,args) do
        ## 不同的类型游戏调用不同的匹配, 改为通过协议实现
        # Golf.Match.match(vs_mode_id,list,args)
        Game.Global.MatchProtocol.match({vs_mode_id,list,args})
    end

    
end