-- Create AIRBOSS object.
local AirbossStennis=AIRBOSS:New("USS Stennis")

-- Add your custom settings here!
AirbossStennis:SetTACAN(74, "X", "STN")
AirbossStennis:SetICLS(5, "STN")
  AirbossStennis:SetMarshalRadio(305)
  AirbossStennis:SetLSORadio(125)
   
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

local menucarriercontrol=MENU_COALITION:New(AirbossStennis:GetCoalition(), "Carrier Control")
MENU_COALITION_COMMAND:New(AirbossStennis:GetCoalition(), "Start CASE I",   menucarriercontrol, StartRecovery, 1)
MENU_COALITION_COMMAND:New(AirbossStennis:GetCoalition(), "Start CASE II",  menucarriercontrol, StartRecovery, 2)
MENU_COALITION_COMMAND:New(AirbossStennis:GetCoalition(), "Start CASE III", menucarriercontrol, StartRecovery, 3)
MENU_COALITION_COMMAND:New(AirbossStennis:GetCoalition(), "Stop Recovery",  menucarriercontrol, StopRecovery)


RescueheloStennis = RESCUEHELO:New(UNIT:FindByName("USS Stennis"), "Stennis Rescue")
RescueheloStennis:Start()