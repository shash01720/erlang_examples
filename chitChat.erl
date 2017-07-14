-module(chitChat).

-import(myLists, [delete/2]).

-export([start/3, start/1, ringLoop/2, starLoop/1, starLoop/2]).


start(Nmsgs) ->
	start(2,Nmsgs,star).

start(Nprocs,Mmsgs, Topo) when ((Topo == ring) orelse (Topo == star))->
   start([],Nprocs,Mmsgs,Topo).


start(PidList,0,Mmsgs,ring) ->
	io:format("Topology: ring ~n"),
	io:format("Pocesses: ~w ~n",[PidList]),
	Last = setNextHop(PidList),
	[First|_] = PidList,
	Last ! {next_hop, First},
	First ! {self(),send,Mmsgs,Last};
start(PidList,0,Mmsgs,star) ->
	[First|Rest] = PidList,
	First ! {next_hop, Rest},
	setNextHop(First,Rest),
	First ! {self(),send,Mmsgs};
start(PidList,Nprocs,Mmsgs, ring) ->
	Pid1 = spawn(chitChat,ringLoop,[unknown,unknown]),
	start(PidList++[Pid1],Nprocs-1,Mmsgs,ring);
start([],Nprocs,Mmsgs, star) ->
	Pid1 = spawn(chitChat,starLoop,[[],[]]),
	start([Pid1],Nprocs-1,Mmsgs,star);
start(PidList,Nprocs,Mmsgs, star) ->
	Pid1 = spawn(chitChat,starLoop,[hd(PidList)]),
	start(PidList++[Pid1],Nprocs-1,Mmsgs,star).
%%
%% Sets Next Hop for Star Topology
%%
setNextHop(_,[]) ->
	done;
setNextHop(First, Rest) ->
	[Next|Rst] = Rest,
	Next ! {next_hop, First},
	setNextHop(First,Rst). 
%%
%% Sets Next Hop for Ring Topology
%%	
setNextHop(N)  when ((is_list(N)) andalso (length(N) >= 2)) ->
	[First|[Next|Rest]] = N,
	First ! {next_hop, Next},
	setNextHop([Next]++Rest);
setNextHop(N) when (length(N) ==1) ->
	hd(N);
setNextHop([]) ->
    done.


ringLoop(NextHop,LastHop) ->
	%%io:format( "Self: ~w, Next: ~w, Last: ~w ~n",[self(),NextHop,LastHop]),
	receive
		{next_hop, N} ->
			io:format(" ~p -NextHop-> ~p ~n ",[self(),N]),
			ringLoop(N,unknown);
		{From,send,Nmsgs,L} ->
			NextHop ! {self(),msg,Nmsgs},
			io:format(" LastHop: ~p ~n", [L]),
			io:format(" Msg ~w : ~p --To--> ~p --> ~p ~n",[Nmsgs,From,self(),NextHop]),
			ringLoop(NextHop,L);
		{From,msg,0} when (LastHop == unknown) ->
			io:format(" Last Msg ~w : From: ~p --To--> ~p --To-->~p ~n",[0,From,self(),NextHop]),
			NextHop ! {self(),msg,0},
			done;
		{From,msg,0} when (LastHop == From) ->
		    done;	
		{From,msg,Nmsgs} when (From /= LastHop)->
			io:format(" Msg ~w : From: ~p --To--> ~p --To-->~p ~n",[Nmsgs,From,self(),NextHop]),
			NextHop ! {self(),msg,Nmsgs},
			ringLoop(NextHop,LastHop);
		{From,msg,Nmsgs} when (From == LastHop) ->
			io:format(" Msg ~w : From: ~p --To--> ~p --To-->~p ~n",[Nmsgs,From,self(),NextHop]),
			NextHop ! {self(),msg,Nmsgs-1},
			ringLoop(NextHop,LastHop)
	end.

starLoop(NextHops,PendingResps) when (is_list(NextHops)) ->
	receive
		{next_hop,Nhs} when (is_list(Nhs)) ->
			io:format("~p -NextHop-> ~w ~n ",[self(),Nhs]),
			starLoop(Nhs,[]);
		{_,send,Nmsgs} ->
			[ (NextHop ! {self(),msg,Nmsgs}) || NextHop <- NextHops],
			io:format( " Msg ~w : From: ~p --To--> ~w ~n",[Nmsgs,self(),NextHops]),
			starLoop(NextHops,NextHops);
		{From,msg,Nmsgs} when ((From == hd(PendingResps)) andalso (Nmsgs =:= 0)) ->
			done;
		{From,msg,_}  when (length(PendingResps) > 1) ->
		    P = myLists:delete(From,PendingResps),
	     	starLoop(NextHops,P);
	     {From,msg,Nmsgs} when (From == hd(PendingResps)) ->
	     	[NextHop ! {self(),msg,Nmsgs-1} || NextHop <- NextHops],
	     	io:format( " Msg ~w : From: ~p --To--> ~w ~n",[Nmsgs,self(),NextHops]),
			starLoop(NextHops,NextHops)
	end.

starLoop(NextHop) ->
	receive
		{next_hop,N} ->
			io:format("~p -NextHop-> ~p ~n ",[self(),N]),
			starLoop(N);
		{_,msg,0} ->
			NextHop ! {self(),msg,0},
			done;
		{_,msg,Nmsgs} ->
			NextHop ! {self(),msg,Nmsgs},
			starLoop(NextHop)
	end.