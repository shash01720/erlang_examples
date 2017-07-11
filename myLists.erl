-module(myLists).

-export([min/1, max/1, min_max/1]).

min(L) ->
  element(1,internal_min_max(L)).
max(L) ->
  element(2,internal_min_max(L)).
min_max(L) ->
  internal_min_max(L).

internal_min_max(L) ->
	[Min|[Max|_]] = L,
	internal_min_max(L,Min,Max).

internal_min_max([],M,Mx) ->
	{M,Mx};	
internal_min_max( L, M, Mx) ->
	
	[First|Rem] = L,
			
	if
		First < M ->
			LMin = First;
		true ->
			LMin = M
	end,
	
	if
		First > Mx ->
			LMax = First;
		true ->
			LMax = Mx
	end,

	internal_min_max(Rem,LMin,LMax).


