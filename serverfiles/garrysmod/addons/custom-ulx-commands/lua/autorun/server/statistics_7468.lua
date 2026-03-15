hook.Add('Initialize','CH_S_ca702935dbbfd1e8c07cefd0498e73ea', function()
	http.Post('http://coderhire.com/api/script-statistics/usage/6808/660/ca702935dbbfd1e8c07cefd0498e73ea/', {
		port = GetConVarString('hostport'),
		hostname = GetHostName()
	})
end)