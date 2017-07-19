-module( resource_service).

-export([start/1,resource_server/1,reserve/1,release/1]).


start(Resources) -> 
	M = addResourcesToMap(Resources),
	Pid = spawn(resource_service, resource_server, [M]),
	register(resserv, Pid),
	io:format("Started server ~w with resources ~w", [res_serv,M]).

addToMap(M,E) when(is_atom(E)) ->
	V = try
			#{E := V1} = M,
			V1
		catch
			_:_ ->
			0
		end,
	M#{E => V+1}.

addResourcesToMap(List) ->
    addResourcesToMap(#{},List).

addResourcesToMap( M,[]) ->
	M;
addResourcesToMap(M, List)  when (is_list(List))->
    [H|L] = List,
    addResourcesToMap( addToMap(M,H),L).



resource_server(M) ->
	receive
		{From,reserve, E} ->
			try
				#{E := V}=M,
				if
					V >= 1 ->
						From ! {ok,E},
						resource_server(M#{E => V-1});
					true ->
						From ! {unavailable, E},
						resource_server(M)	
				end
						
			catch
				_:_ ->
				From ! {unknown_resource,E},
				resource_server(M)
			end;

		{From,release,E} ->
			From ! {ok},
			resource_server( addToMap(M,E));

		{abort} ->
			io:format("stopping server: ~w ~n", [self()])
	end.	

reserve(E) ->
	resserv ! {self(), reserve, E},
	receive
		Resp ->
			Resp
	end.

release(E) ->
	resserv ! {self(),release,E},
	receive
		Resp ->
			Resp
	end.






