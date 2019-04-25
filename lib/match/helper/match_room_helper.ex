defmodule  Game.Global.MatchRoomHelper do
    require Logger

   

    @doc """
        处理玩家进入匹配房间
    """
    def handle_match_room_cast({:enter,request},state) do 
         now = Time.Util.curr_mills()
         %{id: id, player_pid: player_pid, trans_id: trans_id, match_data: match_data}=request
        Logger.info("wait list= #{inspect state.wait_list}")
        case can_enter?(state,id) do 
            true -> 
                Logger.info("id: #{inspect id} enter, exits!")
                {:noreply,state}
            false -> 
                Logger.info("id: #{inspect id} enter, ok!")
                match_id = Map.get(request, :match_id, 0)
                item =%{
                        id: id,
                        player_pid: player_pid,
                        trans_id: trans_id,
                        match_id: match_id,
                        match_data: match_data,
                        enter_time: now,
                        active_time: now,
                        confirm_time: 0,
                        is_confirmed: false,
                        user_data: nil,
                        room_init_data: nil,
                        start_wait_time: now,
                    }
                wait_list=[item| state.wait_list]
                Logger.info("wait list2= #{inspect wait_list}")
                # 如果在playinglist中，删除掉
                playing_list=delete_item(state.playing_list,id)
                {:noreply,%{state| wait_list: wait_list, playing_list: playing_list}}
        end
    end


    @doc """
        更新玩家active状态
    """

    def handle_match_room_cast({:active,request},state) do 
        id=request.id 
        Logger.info("id: #{inspect id} active, ok!")
        wait_list = update_active_time(state.wait_list,id)
        playing_list= update_active_time(state.playing_list,id) 
        playing_with_robot_list= update_active_time(state.playing_with_robot_list,id) 
        {:noreply,%{state|  wait_list: wait_list, 
                            playing_list: playing_list,
                            playing_with_robot_list: playing_with_robot_list}}
    end


    @doc """
        匹配确认
    """
    def handle_match_room_cast({:confirm, request},state) do 
        case request.with_robot do 
            false -> 
                do_confirm(:with_player,request, state)
            true -> 
                do_confirm(:with_robot,request, state)  
        end
    end

   
    @doc """
        离开，打完比赛离开，或者取消匹配时离开
    """
    def handle_match_room_cast({:leave,request},state) do 
         id= request.id 
         Logger.info("id: #{inspect id} leave, ok!")
         %{wait_list: wait_list, 
            playing_list: playing_list, 
            playing_with_robot_list: playing_with_robot_list,
            confirm_list: confirm_list,
            confirm_with_robot_list: confirm_with_robot_list,
            vs_mode_id: vs_mode_id}= state

         wait_list=delete_item(wait_list,id)
         playing_list=delete_item(playing_list,id)
         playing_with_robot_list= delete_item(playing_with_robot_list, id)

         {confirm_list,re_wait_list}= leave_in_confirm_list(vs_mode_id,confirm_list,id)
         confirm_with_robot_list= delete_item(confirm_with_robot_list, id)

         wait_list = Enum.concat(re_wait_list,wait_list)

        {:noreply,%{state|  wait_list: wait_list, 
                            playing_list: playing_list, 
                            playing_with_robot_list: playing_with_robot_list,
                            confirm_list: confirm_list,
                            confirm_with_robot_list: confirm_with_robot_list
                            }}
    end


     # -> {:noreply, state}
     def do_confirm(:with_player,request, state) do 
        %{id: id, room_init_data: room_init_data} = request
        Logger.info("with_player, id: #{inspect id} confirm, ok! request= #{inspect request}")
        now= Time.Util.curr_mills()
        confirm_list= Enum.reverse(state.confirm_list)
        {confirm_list, playing_list}
                = List.foldl(confirm_list,{[],[]},fn(x,{acc1,acc2})-> 
                                {item1,item2}=x
                                case item1.id ==  id || item2.id == id do 
                                    false -> 
                                        {[x| acc1], acc2}
                                    true -> 
                                        ### 如果两个都准备好了，就开始比赛
                                        item1= update_confirm_item(request,item1)
                                        item1= %{item1| room_init_data: room_init_data}
                                        item2=update_confirm_item(request,item2)
                                        item2= %{item2| room_init_data: room_init_data}
                                        case item1.is_confirmed and item2.is_confirmed do 
                                            false -> 
                                                {[{item1,item2} | acc1], acc2}
                                            true -> 
                                                # do start game 
                                                do_match_success(item1,item2,state.vs_mode_id)
                                                item1=confirm_item_2_playing_item(now,item1)
                                                item2=confirm_item_2_playing_item(now,item2)
                                                {acc1,[item1|[item2|acc2]]}
                                        end
                                end
                            end)
        playing_list = Enum.concat(playing_list,state.playing_list)
        {:noreply,%{state| confirm_list: confirm_list, playing_list: playing_list}}
    end


    def do_confirm(:with_robot,request,state) do 
        case Map.has_key?(request,:error) do 
                true -> 
                    do_confirm(:with_robot,:error,request,state)
                false -> 
                    do_confirm(:with_robot,:ok,request,state)
        end
    end

    def do_confirm(:with_robot,:ok,request,state) do 
        %{id: id, room_init_data: room_init_data} = request
        Logger.info("with_robot, id: #{inspect id} confirm, ok! request= #{inspect request}")
        now= Time.Util.curr_mills()
        confirm_with_robot_list= Enum.reverse(state.confirm_with_robot_list)
        {confirm_with_robot_list, playing_with_robot_list}
                = List.foldl(confirm_with_robot_list,{[],[]},fn(x,{acc1,acc2})-> 
                                case x.id ==  id do 
                                    false -> 
                                        {[x| acc1], acc2}
                                    true -> 
                                        ## 更新匹配信息
                                        item1= update_confirm_item(request,x)
                                        item1= %{item1| room_init_data: room_init_data}
                                        item2= nil
                                        do_match_success(item1,item2,state.vs_mode_id)
                                        item1=confirm_item_2_playing_item(now,item1)
                                        {acc1,[item1| acc2]}
                                end
                            end)
        playing_with_robot_list = Enum.concat(playing_with_robot_list,state.playing_with_robot_list)
        {:noreply,%{state| confirm_with_robot_list: confirm_with_robot_list,
                         playing_with_robot_list: playing_with_robot_list}}
    end

    ## 把该玩家重新放入到匹配队列中
    def do_confirm(:with_robot,:error,request,state) do 
        %{id: id } = request
        now= Time.Util.curr_mills()
        confirm_with_robot_list= Enum.reverse(state.confirm_with_robot_list)
        {confirm_with_robot_list,item}= 
                List.foldl(confirm_with_robot_list,{[],nil},fn(x,{acc1,acc2})-> 
                    case x.id == id do 
                        false -> 
                            {[x|acc1],acc2}
                        true -> 
                            {acc1,x}
                    end
                end)
        wait_list= case item do 
                    nil -> 
                        state.wait_list
                    _ -> 
                        ## 重新放回匹配队列
                        item = put_in(item.user_data,nil)
                        item=%{item| 
                                is_confirmed: false,
                                start_wait_time: now
                            }
                        [item|state.wait_list]
                end
        {:noreply,%{state| 
                confirm_with_robot_list: confirm_with_robot_list,
                wait_list: wait_list
            }}
    end




    # -> {confirm_list, re_wait_list}
    def leave_in_confirm_list(vs_mode_id,list,id) do 
        _now= Time.Util.curr_mills()
        list= Enum.reverse(list)
        List.foldl(list,{[],[]},fn(x,{acc1,acc2})-> 
            {item1,item2}=x
            case item1.id == id or item2.id == id do 
                false -> 
                    {[x|acc1],acc2}
                true -> 
                   case item1.id ==id do 
                        false -> 
                            item2 = put_in(item2.user_data,nil)
                            item2=%{item2| is_confirmed: false}
                            active_request(vs_mode_id,item2)
                            {acc1,[item2|acc2]}
                        true -> 
                            item1 = put_in(item1.user_data,nil)
                            item1=%{item1| is_confirmed: false}
                            active_request(vs_mode_id,item1)
                            {acc1,[item1|acc2]}
                   end 
            end
        end)
    end

 
    # -> id(string) | nil
    def get_item_id(item) do 
        if item != nil, do: item.id, else: nil
    end

    # -> ok
    def do_match_success(item1,item2,vs_mode_id) do 
         Logger.info("id1: #{inspect get_item_id(item1)}, id2: #{inspect get_item_id(item2)} match success!")

         request=%{id: item1.id, item1: item1, item2: item2, vs_mode_id: vs_mode_id}
         player_pid = item1.player_pid
         GenServer.cast(player_pid,{item1.trans_id,:match_room_match_success,request})
    end

    # -> item
    def update_confirm_item(request,item) do 
        case item.id == request.id do 
            false -> 
                item
            true -> 
                %{item| is_confirmed: true, user_data: request.user_data}
        end
    end

    
     # -> true | false
     def can_enter?(state, id) do 
        is_exist_in_list?(state.wait_list,id)  or  
        is_exist_in_two_truple_list?(state.confirm_list,id) or 
        is_exist_in_list?(state.confirm_with_robot_list,id)
    end

    # -> true | false
    def is_exist_in_list?(list,id) do 
        case Enum.find(list,fn(x)-> x.id == id end) do 
            nil -> 
                false
            _ -> 
                true
        end
    end

    # -> true | false
    def is_exist_in_two_truple_list?(list,id) do 
        case Enum.find(list,
                        fn(x)->
                            {item1, item2}=x
                            item1.id == id or item2.id == id 
                        end) do 
            nil -> 
                false
            _ -> 
                true
        end
    end

    # -> list
    def update_active_time(list,id) do 
        now = Time.Util.curr_mills()
        Enum.map(list,fn(x)-> 
                        case x.id == id do 
                            false -> 
                                x
                            true -> 
                                %{x| active_time: now}
                        end
                    end)
    end

    # -> list
    def delete_item(list,id) do 
        list= Enum.reverse(list)
        List.foldl(list,[],fn(x,acc)-> 
                    case x.id == id do 
                        true -> 
                            acc
                        false -> 
                            [x|acc]
                    end
                end)
    end

    # def active_list(list) do 
    #     request=%{pid: self()}
    #     for item<-list do 
    #         GenServer.cast(item.player_pid,{item.trans_id,:match_room_player_active,request})
    #     end
    # end

    
    def active_request(vs_mode_id,item) do 
        Logger.info("active id=#{inspect item.id}")
        request=%{id: item.id, vs_mode_id: vs_mode_id}
        GenServer.cast(item.player_pid,{item.trans_id,:match_room_player_active,request})
    end


    # -> list
    def delete_unactive_item(vs_mode_id,list) do 
        now = Time.Util.curr_mills()
        max_unactive_time = Application.get_env(:global_match,:mr_max_unactive_time,30_000)
        check_active_time = Application.get_env(:global_match,:mr_check_active_time,10_000)
        list= Enum.reverse(list)
        List.foldl(list,[],fn(x,acc)-> 
            case x.active_time + max_unactive_time < now do 
                    true -> 
                        acc 
                    false -> 
                        ## check一次active
                        case x.active_time + check_active_time < now do 
                            true -> 
                                active_request(vs_mode_id,x)
                                :ok
                            false -> 
                                :ok 
                        end
                        [x| acc]
            end
        end)
    end

    # -> item
    def confirm_item_2_wait_item(now,vs_mode_id,item) do 
        item = put_in(item.user_data,nil)
        item=%{item| 
            is_confirmed: false,
            start_wait_time: now
        }
        active_request(vs_mode_id,item)
        item 
    end

    def confirm_item_2_playing_item(now,item) do 
        item=put_in(item.user_data,nil)
        %{item|active_time: now}
    end

    # -> {confirm_list, re_wait_list}
    def check_timeout_confirm(:with_player, vs_mode_id, list) do 
        now= Time.Util.curr_mills()
        max_unconfirm_time= Application.get_env(:global_match,:mr_max_unconfirm_time,5_000)
        list= Enum.reverse(list)
        List.foldl(list,{[],[]},fn(x,{acc1,acc2})-> 
                    {item1,item2}=x
                    timeout1=  (item1.confirm_time + max_unconfirm_time < now) and (not item1.is_confirmed)
                    timeout2=  (item2.confirm_time + max_unconfirm_time < now) and (not item2.is_confirmed)

                    case timeout1 do 
                        false -> 
                            case timeout2 do 
                                false -> 
                                    #都没有超时，放回到原等待确认队列中继续等待确认
                                    {[x|acc1],acc2}
                                true -> 
                                    #item2超时了，item1放回到重新等等队列中，进行再次匹配，item2丢弃
                                    item1= confirm_item_2_wait_item(now,vs_mode_id,item1)
                                    {acc1,[item1| acc2]}
                            end
                        true -> 
                            case timeout2 do 
                                false -> 
                                     #item1超时了，item2放回到重新等等队列中，进行再次匹配，item1丢弃
                                    item2 = confirm_item_2_wait_item(now,vs_mode_id,item2)
                                    {acc1,[item2| acc2]}
                                true -> 
                                    ##都超时了，全都丢弃掉
                                    {acc1,acc2}
                            end
                    end
                end)
    end


    # -> {confirm_list, re_wait_list}
    def check_timeout_confirm(:with_robot,_vs_mode_id,list) do 
        now= Time.Util.curr_mills()
        max_unconfirm_time= Application.get_env(:global_match,:mr_max_unconfirm_time,5_000)
        list= Enum.reverse(list)
        List.foldl(list,{[],[]},fn(x,{acc1,acc2})-> 
                    item1= x
                    timeout1=  (item1.confirm_time + max_unconfirm_time < now) and (not item1.is_confirmed)
                    case timeout1 do 
                        false -> 
                            {[x|acc1],acc2}
                        true -> 
                            Logger.info("confirm_time timeout, confirm_time=#{inspect item1.confirm_time}")
                            # 玩家超时，移除掉
                            {acc1,acc2}
                    end
                end)
    end



    def handle_info({:timeout,_timer,:handle_timer}, state) do 
        
        # Logger.error("timeout: handle_timer")
        vs_mode_id=state.vs_mode_id
        wait_list= delete_unactive_item(vs_mode_id,state.wait_list)
        playing_list=delete_unactive_item(vs_mode_id,state.playing_list)
        playing_with_robot_list= delete_unactive_item(vs_mode_id,state.playing_with_robot_list)
        ## 匹配的相关参数
        args=%{user_cnt: state.user_cnt}
        {wait_list, confirm_list, confirm_with_robot_list, extra_data }= Game.Global.Match.match(vs_mode_id,wait_list,args,state.extra_data) 
        confirm_list = Enum.concat(confirm_list,state.confirm_list)
        confirm_with_robot_list = Enum.concat(confirm_with_robot_list,state.confirm_with_robot_list)
        ## 重启定时器
        mr_handle_timer_time= Application.get_env(:global_match,:mr_handle_timer_time,5_000)
        handle_timer= Time.Util.start_timer(mr_handle_timer_time,:handle_timer,state.handle_timer)

        case state.vs_mode_id == 0 do 
            true -> 
                Logger.info(" tiemout handle_tiemr2, wait_list=#{inspect wait_list}, confirm_list=#{inspect confirm_list}, 
                playing_list=#{inspect playing_list}, playing_with_robot_list=#{inspect playing_with_robot_list}")
            false -> 
                :ok
        end

        user_cnt = length(wait_list) + 2 * length(confirm_list) + length(playing_list) + 
                length(confirm_with_robot_list) + length(playing_with_robot_list )
        # Logger.info("user_cnt=#{inspect user_cnt}")
        {:noreply,%{state|
                        wait_list: wait_list, 
                        confirm_list: confirm_list, 
                        confirm_with_robot_list: confirm_with_robot_list,
                        playing_list: playing_list,
                        playing_with_robot_list: playing_with_robot_list,
                        handle_timer: handle_timer,
                        user_cnt: user_cnt,
                        extra_data: extra_data
                        }}
    end

    def handle_info({:timeout,_timer,:confirm_timer},state) do 
        # Logger.error("timeout: confirm_timer")
        {confirm_list, re_wait_list}= check_timeout_confirm(:with_player,state.vs_mode_id, state.confirm_list)

        {confirm_with_robot_list, _l}= check_timeout_confirm(:with_robot,state.vs_mode_id, state.confirm_with_robot_list)

        wait_list= Enum.concat(re_wait_list,state.wait_list)
        ## 重启定时器
        mr_confirm_timer_time= Application.get_env(:global_match,:mr_confirm_timer_time,3_000)
        confirm_timer= Time.Util.start_timer(mr_confirm_timer_time,:confirm_timer,state.confirm_timer)
        # Logger.error("timeout: confirm_timer2...., wait_list=#{inspect wait_list}, confirm_list=#{inspect confirm_list}")
        {:noreply,%{state| 
                        wait_list: wait_list,
                        confirm_list: confirm_list,
                        confirm_with_robot_list: confirm_with_robot_list,
                        confirm_timer: confirm_timer
                        }}
    end




end