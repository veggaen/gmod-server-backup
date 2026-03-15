TEAM_CASINOMANAGER = DarkRP.createJob("Casino Manager", {
    color = Color(255, 255, 0, 255),
    model = "models/player/leet.mdl",
    description = [[You run the casino and keep it under control for the city.]],
    weapons = {},
    command = "casinomanager",
    max = 2,
    salary = 200,
    admin = 0,
    vote = false,
    hasLicense = true,
    candemote = false
})

TEAM_CINEMADIRECTOR = DarkRP.createJob("Cinema Director", {
    color = Color(100, 255, 0, 255),
    model = "models/player/barney.mdl",
    description = [[You run the cinema and build a place where players can watch media.]],
    weapons = {},
    command = "cinemadirector",
    max = 1,
    salary = 300,
    admin = 0,
    vote = true,
    hasLicense = false,
    candemote = false
})

TEAM_BUSDRIVER = DarkRP.createJob("Bus Driver", {
    color = Color(100, 100, 150, 255),
    model = "models/player/eli.mdl",
    description = [[You transport players around the city.]],
    weapons = {},
    command = "busdriver",
    max = 2,
    salary = 500,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = false
})