env.info("Starting dynamic load 2")

function SpawnCASZone(difficulty,mission,attackSet,taskName)
    SPAWN:New("CAS Target "..difficulty)
        :InitRandomizeTemplatePrefixes("Spawn CAS "..difficulty)
        :InitLimit(999,1)
        :OnSpawnGroup(
            function(group,difficulty)
                CommandCenter:MessageToCoalition("New target group located at CAS Target ("..difficulty..").")
                
                group:HandleEvent(EVENTS.Dead)
                function group:OnEventDead(EventData)
                    local unitName = EventData.IniUnitName
                    env.info("CAS unit killed: "..unitName)
                    --local unitGroup = GROUP:Find(EventData.IniDCSGroup)
                    --local groupHealth = unitGroup:GetSize() / unitGroup:GetInitialSize()
                    --MESSAGE:New("CAS target ("..unitName..") killed, group health: "..unitGroup:GetSize().."/"..unitGroup:GetInitialSize(),10,"Debug"):ToBlue()
                end
            end,
            difficulty
        )
        :SpawnScheduled(10,0)
end

-- CAP
Spawn_CAP = {}
ZoneTable_CAP = {
    ZONE:New("Zone Spawn CAP 1"),
    ZONE:New("Zone Spawn CAP 2"),
    ZONE:New("Zone Spawn CAP 3")
}
Spawn_CAP_Avail = true
function SpawnCAP(difficulty)
    if Spawn_CAP_Avail then
        --local previousGroup = SET_GROUP:New():FilterPrefixes("CAP Target "..difficulty):FilterStart():GetFirst()
        
        CommandCenter:MessageToCoalition("EWR has detected incoming enemy air. ("..difficulty..")")
        
        math.random()
        math.random()
        math.random()
        local ZoneCAP = ZoneTable_CAP[math.random(#ZoneTable_CAP)]
        local SpawnObj = Spawn_CAP[difficulty]
        local CapGroup = SpawnObj:SpawnInZone(ZoneCAP,true,6000,10000)
        
        SCHEDULER:New(nil, function(CapGroup)
            if CapGroup ~= nil then
                local alt = CapGroup:GetUnit(1):GetAltitude()
                local speed = CapGroup:GetSpeedMax()*0.3
                local coord = CapGroup:GetCoordinate()
                CapGroup:SetTask(CapGroup:TaskOrbitCircle(alt,speed,coord))
                Spawn_CAP_Avail = false
                SCHEDULER:New(nil, ResetCASDelay, {}, 120)
            else
                MESSAGE:New("Group could not be spawned.",1,"Debug"):ToBlue()
            end
        end, {CapGroup}, 2)

    else
        MESSAGE:New("CAP spawn delay not expired, please wait...",1,"Debug"):ToBlue()
    end
end
function ResetCASDelay()
    Spawn_CAP_Avail = true
    env.info("CAP Spawn enabled")
end
Spawn_CAP["Easy"] = SPAWN:New("CAP Target Easy")
    :InitRandomizeTemplatePrefixes("Spawn CAP Easy")
    :InitLimit(10,9999)
    :InitRepeatOnLanding()
Spawn_CAP["Medium"] = SPAWN:New("CAP Target Medium")
    :InitRandomizeTemplatePrefixes("Spawn CAP Medium")
    :InitLimit(6,9999)
    :InitRepeatOnLanding()
Spawn_CAP["Hard"] = SPAWN:New("CAP Target Hard")
    :InitRandomizeTemplatePrefixes("Spawn CAP Hard")
    :InitLimit(3,9999)
    :InitRepeatOnLanding()
    
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
CommandCenter = COMMANDCENTER:New( HQ, "Pegasus" )
CommandCenter:MessageToCoalition("Operation Kickoff underway. Request tasking using the F10 menu.")

Mission_Watchtower = MISSION
    :New(CommandCenter, "Watchtower", "Primary", "Defend the valley from hostile invasion.", coalition.side.BLUE)

--Mission_Watchtower:Start()

Mission_Overlord = MISSION
    :New(CommandCenter, "Overlord", "Primary", "Conduct offensive strikes.", coalition.side.BLUE)

Mission_Overlord:Start()

---- Setup Menus
MenuSpawn = MENU_COALITION:New( coalition.side.BLUE, "Spawn Menu" )
MenuDebug = MENU_COALITION:New( coalition.side.BLUE, "Debug Menu" )

MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Spawn CAP (Easy)", MenuSpawn, SpawnCAP, "Easy" )
MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Spawn CAP (Medium)", MenuSpawn, SpawnCAP, "Medium" )
MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Spawn CAP (Hard)", MenuSpawn, SpawnCAP, "Hard" )
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Destroy CAP", MenuDebug, DebugDestroyCAP )

MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Destroy one CAS target", MenuDebug,
    function()
        local units = SET_UNIT:New():FilterPrefixes("CAS Target Easy"):FilterStart():GetFirst()
        local unit = units[math.random(#units)]
        unit:GetCoordinate():Explosion(10)
    end
)

MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Destroy VIP target", MenuDebug,
    function()
        local unit = SET_UNIT:New():FilterPrefixes("VIP Target"):FilterStart():GetFirst()
        unit:GetCoordinate():Explosion(10)
    end
)

--A2ADispatcher = AI_A2A_GCICAP:New( { "EWR" }, { "Spawn CAP" }, { "Zone CAP Detection","Zone Enemy CAP" }, 4)

Spawn_CAP_Border = SPAWN:New("CAP Border")
    :InitRandomizeTemplatePrefixes( "Spawn CAP" )
    :InitRepeatOnLanding()
    :InitLimit(2,999)
    :SpawnScheduled(600,0)
    :SpawnScheduleStart()
--
--ZoneCAPDetect = ZONE:New("Zone CAP Detection")
--PatrolCapDetect = AI_PATROL_ZONE:New( ZoneCAPDetect, 3000, 9000, 400, 600 )
--PatrolCapDetect:ManageFuel( 0.2, 60 )
--
--ZoneTable_CAP_Detect_Spawn = {
--    ZONE:New("Zone Spawn CAP Detect 1"),
--    ZONE:New("Zone Spawn CAP Detect 2"),
--    ZONE:New("Zone Spawn CAP Detect 3")
--}
--Spawn_CAP_Detect = SPAWN:New("CAP Detect Target")
--    :InitRandomizeTemplatePrefixes( "Spawn CAP" )
--    :InitRepeatOnLanding()
--    :InitRandomizeZones(ZoneTable_CAP_Detect_Spawn)
--    :OnSpawnGroup(
--        function(group)
--            env.info("CAP Detection group spawned")
--            PatrolCapDetect:SetControllable(group)
--            PatrolCapDetect:__Start(1)
--        end
--    )
----function SpawnCAPDetect()
--    Spawn_CAP_Detect:Spawn()
--end
--MenuDebugSpawnCAPDetect = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "CAP Detect", MenuDebug, SpawnCAPDetect )
--DetectCAPLag = 0
--function ScheduledDetectCAP()
--    ClientsInDetectZone = 0
--    SET_CLIENT:New()
--        :FilterCoalitions("blue")
--        :FilterStart()
--        :ForEachClientInZone(ZoneCAPDetect,
--            function(client)
--                ClientsInDetectZone = ClientsInDetectZone + 1
--            end
--        )
--    env.info("CAP Detect - Clients: "..ClientsInDetectZone)
--    local CountEnemy = SET_GROUP:New():FilterPrefixes("CAP Detect Target"):FilterActive(true):FilterStart():Count()
--    env.info("CAP Detect - CountEnemy: "..CountEnemy)
--    local CountToSpawn = math.max(0,((math.ceil(ClientsInDetectZone/2)) - CountEnemy - DetectCAPLag))
--    env.info("CAP Detect - CountToSpawn: "..CountToSpawn)
--
--    for i=1,CountToSpawn do
--        SpawnCAPDetect()
--        DetectCAPLag = DetectCAPLag + 1
--        SCHEDULER:New(nil, function()
--            env.info("Reducing cap lag")
--            DetectCAPLag = DetectCAPLag - 1
--        end, {}, 20)
--    end
--end
--SCHEDULER:New(nil, ScheduledDetectCAP, {}, 5, 5)

-- Support
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

JTACAutoLase(SPAWN:New("JTAC Easy"):InitLimit(1,999):Spawn():GetName(), 1688)
JTACAutoLase(SPAWN:New("JTAC Medium"):InitLimit(1,999):Spawn():GetName(), 1687)

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

SpawnCASZone("Easy",Mission_Watchtower,BlueAttackSet,"None")
SpawnCASZone("Medium",Mission_Watchtower,BlueAttackSet,"AAA")
SpawnCASZone("Hard",Mission_Watchtower,BlueAttackSet,"AAA/SA-9")

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
