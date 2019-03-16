-- S-3B at USS Stennis spawning on deck.
local tankerStennis=RECOVERYTANKER:New("USS Stennis", "RecoveryTanker")
tankerStennis:SetTACAN(50, "SHE")
tankerStennis:SetRadio(231)
-- Start recovery tanker.
tankerStennis:Start()

-- S-3B at USS Stennis spawning in air.
--local tankerStennis2=RECOVERYTANKER:New("USS Stennis", "RecoveryTanker")

-- Tanker spawns in air.
--tankerStennis2:SetTakeoffAir()

-- Set altitude.
--tankerStennis2:SetAltitude(20000)

-- Start recovery tanker.
--tankerStennis2:Start()


-- Set carrier strike groups to patrol waypoints indefinitely. Once the last waypoint is reached, group will go back to first waypoint.
local StennisGroup=GROUP:FindByName("USS Stennis")
StennisGroup:PatrolRoute()
