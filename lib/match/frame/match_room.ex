defmodule Game.Global.MatchRoom do
  require Logger
  use GenServer


  def name(vs_mode_id) do 
     name=String.to_atom(Atom.to_string(__MODULE__) <>"#{inspect vs_mode_id}")
     Logger.error("name=#{inspect name}")
     name
  end

  # -> nil | pid
  def get_pid(vs_mode_id) do 
    case :erlang.whereis(name(vs_mode_id)) do 
          :undefined ->
            nil
          pid ->
            pid 
    end
  end

  # -> nil | pid
  def get_global_pid(vs_mode_id) do 
    case :global.whereis_name(name(vs_mode_id)) do 
          :undefined ->
            nil
          pid -> 
            pid 
    end
  end

  
  def start_link(%{vs_mode_id: vs_mode_id} = data, _opts \\ []) do
    GenServer.start_link(__MODULE__, data, name: {:global,name(vs_mode_id)})
  end


  @doc """
    等待队列中元素结构,不同的游戏的匹配策略不同，因此数据会有些不一样，
    以下是golf匹配需要的数据：

    item:%{
      id: 玩家ID
      player_pid: 玩家进程
      trans_id: 事件id（暂无用）
      match_id: 匹配标识（相同的id才能匹配到一起）
      match_data： 匹配数据
      enter_time： 进入时间
      active_time： 激活时间
      confirm_time： 匹配确认开始时间
      is_confirmed： 是否已经确认
      user_data: 玩家数据 ，玩家在确认匹配的时候传入
      room_init_data: 房间初始化数据，玩家在确认匹配的时候传入
      start_wait_time: 开始等待的时间
    }

    match_data:%{
      //该部分数据可以根据需要调整（由玩家在匹配时传入）
      lv: 玩家等级
      cup: 玩家杯数
      league_lv: 联盟等级
      mmr: 匹配分数
      win10_cnt: 玩家最近10场比赛赢的次数
      play_all_cnt: 玩家总共参加的比赛次数
      level_ids: 玩家可以参加的比赛id（用于锦标赛）
      level_ids_length: 用于锦标赛匹配
      spec_data: 指定的匹配相关的数据（会影响room_init_data) 
    }
  """
  def init(%{vs_mode_id: vs_mode_id} = _data) do
    Logger.info(" match room init pid=: #{inspect(self())}")
    mr_handle_timer_time= Application.get_env(:global_match,:mr_handle_timer_time,5_000)
    mr_confirm_timer_time= Application.get_env(:global_match,:mr_confirm_timer_time,3_000)

    {:ok, %{
            vs_mode_id: vs_mode_id, # mode_id 区分房间
            wait_list: [], #等待匹配的队列  ［item]
            confirm_list: [], #待确认的队列    [{item1,item2}]
            confirm_with_robot_list: [], #待确认的和robot进行对战的玩家［item]
            playing_list: [], #游戏中的队列 [item]
            playing_with_robot_list: [], #和robot进行比赛的游戏中的玩家队列
            handle_timer: Time.Util.start_timer(mr_handle_timer_time,:handle_timer), ## 处理定时器（每5s做一次处理）
            confirm_timer: Time.Util.start_timer(mr_confirm_timer_time,:confirm_timer), # 检测confirm超时定时器
            user_cnt: 0 # 当前房间的用户数
            }}
  end

  
  def handle_cast({:enter,request},state) do 
      Game.Global.MatchRoomHelper.handle_match_room_cast({:enter,request},state)
  end

  def handle_cast({:active,request},state) do 
      Game.Global.MatchRoomHelper.handle_match_room_cast({:active,request},state)
  end

  def handle_cast({:confirm,request},state) do 
      Game.Global.MatchRoomHelper.handle_match_room_cast({:confirm,request},state)
  end

  def handle_cast({:leave,request},state) do 
      Game.Global.MatchRoomHelper.handle_match_room_cast({:leave,request},state)
  end


  def handle_cast({:test_recv,send_pid,request},state) do 
    recv_pid=self()
    Logger.error("global test_recv : send_pid=#{inspect send_pid}, recv_pid=#{inspect recv_pid}")
    send_pid1= request.send_pid.send_pid
    Logger.error("... send_pid=#{inspect send_pid1}")
    recv_pid= send_pid1
    send_pid= self()
    GenServer.cast(recv_pid,{:test_recv,send_pid})
    {:noreply,state}
  end



  def handle_cast(_msg, state) do
    {:noreply, state}
  end


  def handle_call({:get_room_user_cnt},_from,state) do 
      reply= state.user_cnt
      {:reply,reply,state}
  end

  def handle_call({:get_play_with_robot_room_user_cnt},_from,state) do 
      reply= length(state.playing_with_robot_list)
      {:reply, reply,state}
  end


  def handle_call(_msg, _from, state) do
    {:noreply, state}
  end

  def handle_info({:timeout, timer, :handle_timer},state) do 
      Game.Global.MatchRoomHelper.handle_info({:timeout,timer,:handle_timer},state)
  end

  def handle_info({:timeout, timer, :confirm_timer},state) do 
      Game.Global.MatchRoomHelper.handle_info({:timeout,timer,:confirm_timer},state)
  end


  def handle_info(_msg, state) do 
      {:noreply, state}
  end


  def terminate(_reason, _state) do
    :ok
  end

end
