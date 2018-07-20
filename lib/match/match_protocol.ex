defprotocol Game.Global.MatchProtocol do
    @fallback_to_any true

    def match(data)
    
  end
  

## 这里仅仅是用于编译，具体的实现在自己的项目匹配逻辑中
# -> {left_list,confirm_list,confirm_with_robot_list}
defimpl Game.Global.MatchProtocol, for: Integer do
  require  Logger
      def match(_) do 
        # Logger.info("match protocol impl for integer")
        {[],[],[]}
      end
end
  
# 编译中警告没有any的实现，在自己的项目中实现类似如下逻辑
# defimpl Game.Global.MatchProtocol, for: Any do
#   require  Logger
#       def match(_) do 
#         # Logger.info("match protocol impl for any")
#         {[],[],[]}
#       end
# end


  