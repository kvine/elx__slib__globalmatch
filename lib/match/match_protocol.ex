defprotocol Game.MatchRoom.MatchProtocol do
   
    @moduledoc """
     实现自己项目的匹配逻辑
    """
    def match(vs_mode_id,wait_list,args)
  end
  

  