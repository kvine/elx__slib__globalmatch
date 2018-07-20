defmodule Game.Global.Match.Supervisor do
	use Supervisor
	require  Logger
	
	def start_link() do
		Supervisor.start_link(__MODULE__, nil, [name: __MODULE__])
	end
 
	def init(nil) do
		
		match_room_sup_spec=  supervisor(Game.Global.MatchRoom.Supervisor, [Game.Global.MatchRoom], restart: :permanent)
		
		children=[
				match_room_sup_spec
					]
		Logger.error("Match Supervisor start !!!!!")
		supervise(children, strategy: :one_for_one)
	end

end