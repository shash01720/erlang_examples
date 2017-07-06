-module(lcm).
-compile(export_all).

dolcm(Numa,Numb,Facta,Factb) ->
        X = Numa*Facta,
	Y = Numb*Factb,

	if
		X < Y ->
			dolcm(Numa,Numb,Facta+1,Factb);
		X > Y ->
			dolcm(Numa,Numb,Facta,Factb+1);
		true ->
			Numa*Facta
	end.
dolcm(Numa,Numb) ->
	dolcm(Numa,Numb,1,1).
