env.info("Starting dynamic load 2")

CAS_TaskInfo = {}

function SpawnCASZone(difficulty,mission,attackSet,taskName)
    local TaskInfo = {}
    
    local spawnGroup = SPAWN:New("CAS Target "..difficulty)
        :InitRandomizeTemplatePrefixes("Spawn CAS "..difficulty)
        :InitLimit(999,1)
        :OnSpawnGroup(
            function(group,difficulty)
                CommandCenter:MessageToCoalition("New target group located at CAS Target ("..difficulty..").")
                
                group:HandleEvent(EVENTS.Dead)
                function group:OnEventDead(EventData)
                    env.info("unit killed")
                    local unitGroup = GROUP:Find(EventData.IniDCSGroup)
                    local unitName = EventData.IniUnitName
                    local groupHealth = unitGroup:GetSize() / unitGroup:GetInitialSize()
                    MESSAGE:New("CAS target ("..unitName..") killed, group health: "..unitGroup:GetSize().."/"..unitGroup:GetInitialSize(),10,"Debug"):ToBlue()
                end
            end,
            difficulty
        )
        :SpawnScheduled(60,0)

    TaskInfo.group = spawnGroup

    --TaskInfo.task = TASK_A2G_CAS:New(
    --    mission,
    --    attackSet,
    --    "CAS "..difficulty.." ("..taskName..")",
    --    SET_UNIT:New():FilterPrefixes("CAS Target "..difficulty):FilterStart(),
    --    "Engage "..difficulty.." CAS targets (AA Threat: "..taskName..")"
    --)
    
    TaskInfo.jtac = SPAWN:New("JTAC "..difficulty)
        :InitLimit(1,999)
        :Spawn()
    
    CAS_TaskInfo[difficulty] = TaskInfo
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
                SCHEDULER:New(nil, ResetCASDelay, {}, 20)
                
                --if previousGroup
                --    if previousGroup:GetName() == CapGroup:GetName() then
                --        CommandCenter:MessageToCoalition("Group not spawned, previous group still active")
                --    end
                --end
            end
        end, {CapGroup}, 2)
        
        
        
    else
        env.info("CAP Spawn delayed")
    end
end
function ResetCASDelay()
    Spawn_CAP_Avail = true
    env.info("CAP Spawn enabled")
end
Spawn_CAP["Easy"] = SPAWN:New("CAP Target Easy")
    :InitRandomizeTemplatePrefixes("Spawn CAP Easy")
    :InitLimit(2,999)
    :InitRepeatOnLanding()
Spawn_CAP["Medium"] = SPAWN:New("CAP Target Medium")
    :InitRandomizeTemplatePrefixes("Spawn CAP Medium")
    :InitLimit(2,999)
    :InitRepeatOnLanding()
Spawn_CAP["Hard"] = SPAWN:New("CAP Target Hard")
    :InitRandomizeTemplatePrefixes("Spawn CAP Hard")
    :InitLimit(2,999)
    :InitRepeatOnLanding()

-- SAMs
local SpawnCountSamZones = 5
local ZoneTable_SAM = {}
for sam_i=1,5,1 do
  table.insert(ZoneTable_SAM, ZONE:New("Zone SAM "..sam_i))
end
Spawn_SAM_Target = SPAWN:New( "SAM Target" )
    :InitRandomizeTemplatePrefixes( "Spawn SAM" )
    :InitRandomizeZones(ZoneTable_SAM)
    :InitLimit(9999, SpawnCountSamZones)

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

Mission_Watchtower:Start()

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

Spawn_CAP_Border = SPAWN:New("CAP Border")
    :InitRandomizeTemplatePrefixes( "Spawn CAP" )
    :InitRepeatOnLanding()
    :InitLimit(2,999)
    :SpawnScheduled(600,0)
    :SpawnScheduleStart()

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

-- Tasking
CASAttackSet = SET_GROUP:New()
    :FilterCoalitions("blue")
    :FilterStart()

JTACSet = SET_GROUP:New()
    :FilterPrefixes( "JTAC" )
    :FilterStart()

env.info("Creating tasks")

SpawnCASZone("Easy",Mission_Watchtower,CASAttackSet,"None")
SpawnCASZone("Medium",Mission_Watchtower,CASAttackSet,"AAA")
SpawnCASZone("Hard",Mission_Watchtower,CASAttackSet,"AAA/SA-9")

--JtacDetection = DETECTION_AREAS:New( JTACSet, 20000 )
--
--CASDispatcher = TASK_A2G_DISPATCHER:New(Mission_Watchtower, CASAttackSet, JtacDetection)

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
    else
        timer.scheduleFunction(checkVIPStatus, {}, timer.getTime() + 60)
    end
end

MonitorVIPStatus()
