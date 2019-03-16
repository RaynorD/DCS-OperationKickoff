-- Parameters
local SpawnCountCasZones = 20
local SpawnCountSamZones = 5

-- Zone Groups
local ZoneTable_CAS = {}
local ZoneTable_SAM = {}

for cas_i=1,30,1 do
  table.insert(ZoneTable_CAS, ZONE:New("Zone CAS "..cas_i))
end
for sam_i=1,13,1 do
  table.insert(ZoneTable_SAM, ZONE:New("Zone SAM "..sam_i))
end
--
--function SpawnCASTarget()
--  Spawn_Group_CAS_Target:Spawn()
--end

Spawn_CAS_Target = SPAWN:New( "CAS Target" )
  :InitRandomizeTemplatePrefixes( "Spawn CAS" ) 
  :InitRandomizeZones(ZoneTable_CAS)
  :InitLimit(9999, SpawnCountCasZones)
  
Spawn_SAM_Target = SPAWN:New( "SAM Target" )
  :InitRandomizeTemplatePrefixes( "Spawn SAM" ) 
  :InitRandomizeZones(ZoneTable_SAM)
  :InitLimit(9999, SpawnCountSamZones)
  
for i=1,SpawnCountCasZones,1 do
  Spawn_CAS_Target:Spawn()
end
for i=1,SpawnCountSamZones,1 do
  Spawn_SAM_Target:Spawn()
end

-- Settings
_SETTINGS:SetPlayerMenuOn()
_SETTINGS:SetA2G_LL_DMS()

---- Command Center
HQ = GROUP:FindByName("HQ")
CommandCenter = COMMANDCENTER:New( HQ, "Pegasus" )
CommandCenter:MessageToCoalition("Operation Kickoff underway. Request tasking using the F10 menu.")

Mission_Watchtower = MISSION
  :New(CommandCenter, "Watchtower", "Primary", "Defend the valley from hostile invasion.", coalition.side.BLUE)

Mission_Overlord = MISSION
  :New(CommandCenter, "Overlord", "Primary", "Conduct offensive strikes.", coalition.side.BLUE)

---- Setup Menus
MenuTesting = MENU_COALITION:New( coalition.side.BLUE, "Spawn Menu" )

--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Spawn CAP", MenuTesting, SpawnCAPTarget )
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Destroy CAP", MenuTesting, DebugDestroyCAP )

MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Destroy one CAS target", MenuTesting,
  function() 
    local units = JTACCurrentTargetGroup:GetUnits()
    local unit = units[math.random(#units)]
    unit:Destroy(true)
  end
)

Spawn_CAP_Border = SPAWN:New("CAP Border")
  :InitRandomizeTemplatePrefixes( "Spawn CAP" )
  :InitRepeatOnLanding()
  :InitLimit(2,999)
  :SpawnScheduled(3600,0)
  :SpawnScheduleStart()

Texaco_Spawn = SPAWN:New("Texaco")
  :InitRepeatOnLanding()
  :InitLimit(1,999)
  :SpawnScheduled(60,0)
  :SpawnScheduleStart()
  
Arco_Spawn = SPAWN:New("Arco")
  :InitRepeatOnLanding()
  :InitLimit(1,999)
  :SpawnScheduled(60,0)
  :SpawnScheduleStart()
  
AWACS_Spawn = SPAWN:New("USA AWACS")
  :InitRepeatOnLanding()
  :InitLimit(1,999)
  :SpawnScheduled(60,0)
  :SpawnScheduleStart()

function JTACMoveToNearestGroup()
  -- FindNearestGroupFromPointVec2 is getting nil data after group respawn
  local ClosestEnemyGroup = SET_GROUP:New()
    :FilterPrefixes("CAS Target")
    :FilterOnce()
    :FindNearestGroupFromPointVec2(JTACGroup:GetPointVec2())
  
  JTACCurrentTargetGroup = ClosestEnemyGroup
  
  local pos = ClosestEnemyGroup:GetCoordinate()
  
  MESSAGE:New("JTAC orbiting new target group at "..pos:ToStringLLDMS(),10,"JTAC"):ToBlue()
  
  JTACGroup:SetTask(JTACGroup:TaskOrbitCircle(2000,150,pos))
end

function JTACScheduled()
  MESSAGE:New("Target group ("..#(JTACCurrentTargetGroup:GetUnits())..") health: "..JTACCurrentTargetGroup:GetLife().." / "..JTACCurrentTargetGroup:GetLife0(),10,"JTAC"):ToBlue()
  if #(JTACCurrentTargetGroup:GetUnits()) <= 2 then
    JTACCurrentTargetGroup:Destroy(true)
    MESSAGE:New("Target group is in retreat. JTAC finding new target group.",10,"JTAC"):ToBlue()
    SCHEDULER:New(JTACGroup, JTACMoveToNearestGroup, {}, 5)
  end
end

function onJTACSpawn(group)
  JTACGroup = group
  JTACMoveToNearestGroup()

  if JTAC_Designate ~= nil then
    JTAC_Designate:Remove()
  end
  
  JTAC_Designate = DESIGNATE:New(CommandCenter, JtacDetection, CASAttackSet)
  JTAC_Designate:SetLaserCodes({1688})

  JtacScheduler = SCHEDULER:New(JTACGroup, JTACScheduled, {}, 5, 5)
end

JTAC_1_Spawn = SPAWN:New("JTAC 1")
  :InitRepeatOnLanding()
  :InitLimit(1,999)
  :OnSpawnGroup(onJTACSpawn)
  :SpawnScheduled(60,0)
  :SpawnScheduleStart()

CASAttackSet = SET_GROUP:New()
  :FilterCoalitions("blue")
  :FilterStart()

JTACSet = SET_GROUP:New()
  :FilterPrefixes( "JTAC" )
  :FilterCoalitions("blue")
  :FilterStart()

JtacDetection = DETECTION_AREAS:New( JTACSet, 20000 )

CASDispatcher = TASK_A2G_DISPATCHER:New(Mission_Watchtower, CASAttackSet, JtacDetection)

