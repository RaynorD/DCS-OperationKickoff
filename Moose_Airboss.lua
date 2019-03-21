-- Create AIRBOSS object.
local AirbossStennis=AIRBOSS:New("USS Stennis")

-- Add your custom settings here!
AirbossStennis:SetTACAN(74, "X", "STN")
AirbossStennis:SetICLS(5, "STN")
AirbossStennis:SetMarshalRadio(305)
AirbossStennis:SetLSORadio(125)
AirbossStennis:SetSoundfilesFolder("Airboss Soundfiles/")
AirbossStennis:SetMenuSingleCarrier()

-- Load all saved player grades from your "Saved Games\DCS" folder (if lfs was desanitized).
AirbossStennis:Load()

-- Automatically save player results to your "Saved Games\DCS" folder each time a player get a final grade from the LSO.
AirbossStennis:SetAutoSave()

-- Enable trap sheet.
AirbossStennis:SetTrapSheet()
   
-- Delete auto recovery window.
function AirbossStennis:OnAfterStart(From,Event,To)
  self:DeleteAllRecoveryWindows()
end

-- Start airboss script.
AirbossStennis:Start()

-- Start recovery function.
local function StartRecovery(case)

  -- Recovery staring in 5 min for 30 min.
  local t0=timer.getAbsTime()+5*60
  local t9=t0+30*60
  local C0=UTILS.SecondsToClock(t0)
  local C9=UTILS.SecondsToClock(t9)

  -- Carrier will turn into the wind. Wind on deck 25 knots. U-turn on.
  AirbossStennis:AddRecoveryWindow(C0, C9,case, 30, true, 25, true)
end

-- Stop recovery function.
local function StopRecovery()
  AirbossStennis:RecoveryStop()
end

local menucarriercontrol=MENU_COALITION:New(AirbossStennis:GetCoalition(), "Airboss")
MENU_COALITION_COMMAND:New(AirbossStennis:GetCoalition(), "Start CASE I",   menucarriercontrol, StartRecovery, 1)
MENU_COALITION_COMMAND:New(AirbossStennis:GetCoalition(), "Start CASE II",  menucarriercontrol, StartRecovery, 2)
MENU_COALITION_COMMAND:New(AirbossStennis:GetCoalition(), "Start CASE III", menucarriercontrol, StartRecovery, 3)
MENU_COALITION_COMMAND:New(AirbossStennis:GetCoalition(), "Stop Recovery",  menucarriercontrol, StopRecovery)

RescueheloStennis = RESCUEHELO:New("USS Stennis", "Stennis Rescue")
RescueheloStennis:Start()

-- S-3B at USS Stennis spawning on deck.
local tankerStennis=RECOVERYTANKER:New("USS Stennis", "Stennis Tanker")
tankerStennis:SetTACAN(50, "SHE")
tankerStennis:SetRadio(230)
-- Start recovery tanker.
tankerStennis:Start()

-- Set carrier strike groups to patrol waypoints indefinitely. Once the last waypoint is reached, group will go back to first waypoint.
local StennisGroup=GROUP:FindByName("USS Stennis")
StennisGroup:PatrolRoute()
