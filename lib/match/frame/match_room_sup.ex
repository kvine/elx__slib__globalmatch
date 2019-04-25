defmodule Game.Global.MatchRoom.Supervisor do
    use Elixir.Supervisor

    def start_link(module) do
      Elixir.Supervisor.start_link(__MODULE__, module, name: __MODULE__)
    end

    def start_child(data) do
      Elixir.Supervisor.start_child(__MODULE__, [data])
    end

    def init(module) do
        ## 初始化所有的模式
        #获取所有的模式id, 目前设置50个足够用了
        vs_mode_ids= 0..49
        # vs_mode_ids=[0,1]
        children=  for i<- vs_mode_ids do 
                    id= Game.Global.MatchRoom.name(i)
                    worker(module,[%{vs_mode_id: i}], restart: :permanent, id: id)
                    end
        supervise(children, strategy: :one_for_one)
    end
end