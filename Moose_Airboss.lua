-- Create AIRBOSS object.
local AirbossStennis=AIRBOSS:New("USS Stennis")

-- Add your custom settings here!
AirbossStennis:SetTACAN(74, "X", "STN")
AirbossStennis:SetICLS(5, "STN")
AirbossStennis:SetMarshalRadio(305)
AirbossStennis:SetLSORadio(125)
AirbossStennis:SetSoundfilesFolder("Airboss Soundfiles/")

RescueheloStennis = RESCUEHELO:New("USS Stennis", "Stennis Rescue")
RescueheloStennis:Start()

-- S-3B at USS Stennis spawning on deck.
local tankerStennis=RECOVERYTANKER:New("USS Stennis", "Stennis Tanker")
tankerStennis:SetTACAN(50, "SHE")
tankerStennis:SetRadio(230)
-- Start recovery tanker.
tankerStennis:Start()
