env.info("Starting dynamic load 2")

function SpawnCASZone(difficulty)
    env.info("Spawning CAS Target ("..difficulty..")")
    SPAWN:New("CAS Target "..difficulty)
        :InitRandomizeTemplatePrefixes("Spawn CAS "..difficulty)
        :Spawn()
end

PolygonZoneBase = ZONE_POLYGON:NewFromGroupName("Zone Polygon Base")
PolygonZoneBorder = ZONE_POLYGON:NewFromGroupName("Zone Polygon Border")

-- CAP
Spawn_CAP = {}
BorderAirbaseTable_CAP = {
    AIRBASE:FindByName("Mineralnye Vody"),
    AIRBASE:FindByName("Nalchik"),
    --AIRBASE:FindByName("Mozdok"),
    AIRBASE:FindByName("Beslan")
}
function CAPStartPatrol(CapGroup,patrolObj)
    if CapGroup:InAir() then
        env.info("CAP group starting patrol: "..CapGroup:GetName())
        patrolObj:Start()
    else
        SCHEDULER:New(nil,CAPStartPatrol,{CapGroup,patrolObj},10)
    end
end
function CAPPostSpawn(CapGroup,CapZone)
    if CapGroup ~= nil then
        env.info("CAP group spawned: "..CapGroup:GetName())
        local patrolObj = AI_CAP_ZONE:New(CapZone,3000,9000,400,600)
        patrolObj:SetControllable(CapGroup)
        patrolObj:SetEngageRange(92600)
        patrolObj:SetRefreshTimeInterval(120)
        patrolObj:ManageDamage(0.5)
        patrolObj:ManageFuel(0.2, 0)

        SCHEDULER:New(nil,CAPStartPatrol,{CapGroup,patrolObj},10)
    else
        env.info("Group could not be spawned.")
    end
end

function SpawnCAPBorder(difficulty)
    math.random()
    math.random()
    math.random()
    if difficulty == nil then
        local ds = {"Easy","Medium","Hard"}
        difficulty = ds[math.random(#ds)]
    end
    local base = BorderAirbaseTable_CAP[math.random(#BorderAirbaseTable_CAP)]
    local SpawnObj = Spawn_CAP[difficulty]
    local CapGroup = SpawnObj:SpawnAtAirbase(base)
    CAPPostSpawn(CapGroup,PolygonZoneBorder)
end

Spawn_CAP["Easy"] = SPAWN:New("CAP Target Easy")
    :InitRandomizeTemplatePrefixes("Spawn CAP Easy")
    --:InitLimit(10,0)
    :InitRepeatOnLanding()
Spawn_CAP["Medium"] = SPAWN:New("CAP Target Medium")
    :InitRandomizeTemplatePrefixes("Spawn CAP Medium")
    --:InitLimit(6,0)
    :InitRepeatOnLanding()
Spawn_CAP["Hard"] = SPAWN:New("CAP Target Hard")
    :InitRandomizeTemplatePrefixes("Spawn CAP Hard")
    --:InitLimit(3,0)
    :InitRepeatOnLanding()

CAPTestOffset = 0
function ScheduledDetectCAP()
    ClientsActive = SET_CLIENT:New()
        :FilterCoalitions("blue")
        :FilterCategories("plane")
        :FilterActive()
        :FilterStart()
        :Count() + 3 + CAPTestOffset
    
    env.info("CAP Detect - Clients: "..ClientsActive)
    local CountEnemy = SET_GROUP:New():FilterPrefixes("CAP Target"):FilterActive(true):FilterStart():Count()
    env.info("CAP Detect - CountEnemy: "..CountEnemy)
    local CountToSpawn = ClientsActive - CountEnemy
    env.info("CAP Detect - CountToSpawn: "..CountToSpawn)

    if CountToSpawn > 0 then
        SpawnCAPBorder()
    end
end
SCHEDULER:New(nil, ScheduledDetectCAP, {}, 300, 300, 0.6)

Spawn_CAP_RedBase = SPAWN:New("CAP Red Base")
    :InitRandomizeTemplatePrefixes( "Spawn CAP Medium" )
    :InitRepeatOnLanding()
    :InitLimit(3,0)
    :OnSpawnGroup(CAPPostSpawn,PolygonZoneBase)

Spawn_CAP_RedBase:Spawn()
Spawn_CAP_RedBase:Spawn()
Spawn_CAP_RedBase:Spawn()
Spawn_CAP_RedBase:SpawnScheduled(600,0.5)
    :SpawnScheduleStart()

SpawnCAPBorder()
SpawnCAPBorder()
SpawnCAPBorder()

-- SAMs
local CountSamZones = 14
local SpawnCountSamZones = 5 -- do not set lower than CountSamZones
local ZoneTable_SAM = {}
for i=1,CountSamZones do
  table.insert(ZoneTable_SAM, ZONE:New("Zone SAM "..i))
end
Spawn_SAM_Target = SPAWN:New( "SAM Target" )
    :InitRandomizeTemplatePrefixes( "Spawn SAM" )
math.random()
math.random()
math.random()
for i=1,SpawnCountSamZones do
    local sam_i = math.random(#ZoneTable_SAM)
    local zone = table.remove(ZoneTable_SAM,sam_i)
    Spawn_SAM_Target:SpawnInZone(zone,true)
end

-- Settings
_SETTINGS:SetPlayerMenuOn()
_SETTINGS:SetA2G_LL_DMS()

---- Command Center
HQ = GROUP:FindByName("HQ")
CommandCenter = COMMANDCENTER:New( HQ, "Command" )
CommandCenter:MessageToCoalition("Operation Kickoff underway. View available tasks in the mission briefing.")

---- Debug Menus
--MenuDebug = MENU_COALITION:New( coalition.side.BLUE, "Debug Menu" )
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Spawn Border CAP", MenuDebug, SpawnCAPBorder, "Medium")
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Spawn Base CAP", MenuDebug,function()
--    Spawn_CAP_RedBase:Spawn()
--end)
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Increase detect offset", MenuDebug, function()
--    CAPTestOffset = CAPTestOffset + 1
--end)
--
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Destroy one CAS target", MenuDebug,
--    function()
--        local units = SET_UNIT:New():FilterPrefixes("CAS Target Easy"):FilterStart():GetFirst()
--        local unit = units[math.random(#units)]
--        unit:GetCoordinate():Explosion(10)
--    end
--)
--
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Destroy VIP target", MenuDebug,
--    function()
--        local unit = SET_UNIT:New():FilterPrefixes("VIP Target"):FilterStart():GetFirst()
--        unit:GetCoordinate():Explosion(10)
--    end
--)

-- Support
Texaco_Spawn = SPAWN:New("Texaco")
    :InitRepeatOnLanding()
    :InitLimit(1,0)
    :SpawnScheduled(60,0)
    :SpawnScheduleStart()
    
Arco_Spawn = SPAWN:New("Arco")
    :InitRepeatOnLanding()
    :InitLimit(1,0)
    :SpawnScheduled(60,0)
    :SpawnScheduleStart()
    
AWACS_Spawn = SPAWN:New("USA AWACS")
    :InitRepeatOnLanding()
    :InitLimit(1,0)
    :SpawnScheduled(60,0)
    :SpawnScheduleStart()

JTACAutoLase(SPAWN:New("JTAC Easy"):InitLimit(1,0):Spawn():GetName(), 1688)
JTACAutoLase(SPAWN:New("JTAC Medium"):InitLimit(1,0):Spawn():GetName(), 1687)

-- Tasking
BlueAttackSet = SET_GROUP:New()
    :FilterCoalitions("blue")
    :FilterStart()

JTACSet = SET_GROUP:New()
    :FilterPrefixes( "JTAC" )
    :FilterStart()

env.info("Creating tasks")

-- Tasks
--CAPTargetSet = SET_UNIT:New():FilterCoalitions("red"):FilterCategories("plane"):FilterStart()
--Task_CAP = TASK_A2A_SWEEP:New(Mission_Watchtower, BlueAttackSet, "Combat Air Patrol", CAPTargetSet, "Maintain air superiority in the valley.")

function MonitorCAPTask()
    local playerCount = Task_CAP:GetPlayerCount()
    MESSAGE:New("Players assigned to CAP: "..playerCount,5,"Debug"):ToBlue()
end
--Task_CAP_Scheduler = SCHEDULER:New(nil, MonitorCAPTask, {}, 5, 5)

SpawnCASZone("Easy")
SpawnCASZone("Medium")
SpawnCASZone("Hard")

-- VIP Aircraft ===================================================================================
local vipSpawns = {
    "VIP Target Nalchik",
    "VIP Target Mineralnye",
    "VIP Target Mozdok",
    "VIP Target Beslan"
}
math.random()
math.random()
math.random()
local randomVip = math.random(#vipSpawns)
MESSAGE:New("Vip selection: "..randomVip.."/"..#vipSpawns,10,"Debug"):ToBlue()
SPAWN:New(vipSpawns[randomVip])
    :InitUnControlled(true)
    :Spawn()

function MonitorVIPStatus()
    if SET_UNIT:New():FilterPrefixes("VIP Target"):FilterStart():GetFirst():GetLife() < 10 then
        MESSAGE:New("Vip transport confirmed to be neutralized, well done.",10,"Debug"):ToBlue()
        VIPScheduler:Stop()
    end
end

VIPScheduler = SCHEDULER:New(nil, MonitorVIPStatus, {}, 60, 60)
