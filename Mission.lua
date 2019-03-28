
-- Settings
_SETTINGS:SetA2G_LL_DMS()
_SETTINGS:SetImperial()
_SETTINGS:SetPlayerMenuOn()

---- Command Center
HQ = GROUP:FindByName("HQ")
CommandCenter = COMMANDCENTER:New( HQ, "Command" )
CommandCenter:MessageToCoalition("Operation Kickoff underway. View available tasks in the mission briefing.")


--MenuDebug = MENU_COALITION:New( coalition.side.BLUE, "Debug Menu" )
function DestroyGroups(pre)
  local set = SET_GROUP:New():FilterPrefixes(pre):FilterStart()
  if set:Count() > 0 then
    set:ForEachGroup(function(g) g:Destroy() end)
  end
end

function FindFirstGroupByPrefix(pre)
    return SET_GROUP:New():FilterPrefixes(pre):FilterStart():GetFirst()
end

function GetOriginalSpawnName(group)
    local currentGroupName = group:GetName()
    local hashIndex = string.find(currentGroupName, "#")
    return string.sub(currentGroupName,0,hashIndex-1)
end
math.random()
math.random()
math.random()
env.info("Kickoff: init start")
-- CAS Targets
env.info("Kickoff: CAS init start")

CAS_Groups = {}
function SpawnCASZone(diff)
    env.info("(Re)Spawning CAS Target ("..diff..")")
    local CasGroup = SPAWN:New("CAS Target "..diff)
        :InitRandomizeTemplatePrefixes("Spawn CAS "..diff)
        :SpawnInZone(ZONE:New("Zone CAS "..diff), true)

    CAS_Groups[CasGroup:GetName()] = diff
    
    CasGroup:HandleEvent(EVENTS.Dead)
    function CasGroup:OnEventDead(EventData)
        local unitGroup = EventData.IniGroup
        local diff = unitGroup[CasGroup:GetName()]
        if CAS_Respawning[diff] == true then
            env.info("Group respawning, skipping health check ("..diff..") - spawn busy")
        else
            --local unitName = EventData.IniUnitName
            --local groupHealth = unitGroup:GetSize() / unitGroup:GetInitialSize()
            --env.info("CAS target ("..unitName..") killed, group health: "..groupHealth)
            --if groupHealth <= 0.3 then
            if unitGroup:GetSize() <= 2 then
                CAS_Respawning[diff] = true
                SCHEDULER:New(nil,function(diff)
                    CommandCenter:MessageToCoalition("CAS target group ("..diff..") is in retreat, standby for new target")
                end,{diff},10)
                SCHEDULER:New(nil,DestroyGroups,{"CAS Target "..diff},20)
                SCHEDULER:New(nil,SpawnCASZone,{diff},30)
            end
        end
    end
    CAS_Respawning[diff] = false
end

Table_CASTargets = {"Easy","Medium","Hard"}
CAS_Respawning = {}

for i, diff in ipairs(Table_CASTargets) do
    SpawnCASZone(diff)
    CAS_Respawning[diff] = false
end
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Destroy one CAS target", MenuDebug,
--    function()
--        local units = SET_UNIT:New():FilterPrefixes("CAS Target Easy"):FilterStart()
--        if units:Count() > 0 then
--            MESSAGE:New("Destroying easy cas unit",5,"Debug"):ToBlue()
--            units:GetRandom():GetCoordinate():Explosion(10)
--        else
--            MESSAGE:New("No unit found",5,"Debug"):ToBlue()
--        end
--    end
--)
local CasSpawnCountBase = 6
local ZoneSetCasBase = SET_ZONE:New():FilterPrefixes("Zone CAS Base"):FilterStart()
Spawn_CAS_Base = SPAWN:New( "CAS Target Base" )
    :InitRandomizeTemplatePrefixes( "Spawn CAS" )
for i=1,CasSpawnCountBase do
    local zone = ZoneSetCasBase:GetRandom()
    ZoneSetCasBase:RemoveZonesByName(zone:GetName())
    Spawn_CAS_Base:SpawnInZone(zone,true)
end
env.info("Kickoff: CAS init done")

-- CAP
env.info("Kickoff: CAP init start")

Spawn_CAP = {}
CAPBorderAirbases = {
    AIRBASE:FindByName("Mineralnye Vody"),
    AIRBASE:FindByName("Nalchik"),
    AIRBASE:FindByName("Beslan")
}
CAPPatrolZonesBorder = SET_ZONE:New():FilterPrefixes("Zone CAP Patrol"):FilterStart()
CAPPatrolZonesBase = SET_ZONE:New():FilterPrefixes("Zone CAP Base"):FilterStart()
function CAPStartPatrol(CapGroup,patrolObj)
    if CapGroup:InAir() then
        env.info("CAP group starting patrol: "..CapGroup:GetName())
        patrolObj:Start()
    else
        SCHEDULER:New(nil,CAPStartPatrol,{CapGroup,patrolObj},10)
    end
end
function CAPOnSpawnGroup(CapGroup,SetZones)
    if CapGroup ~= nil then
        local patrolZone = SetZones:GetRandom()
        env.info("CAP group spawned: "..CapGroup:GetName().." - Zone: "..patrolZone:GetName())
        local patrolObj = AI_CAP_ZONE:New(patrolZone,3000,9000,700,1200)
        patrolObj:SetControllable(CapGroup)
        patrolObj:SetEngageRange(92600) -- 50 nm
        patrolObj:SetRefreshTimeInterval(120)
        patrolObj:ManageDamage(0.5)
        patrolObj:ManageFuel(0.2, 0)

        SCHEDULER:New(nil,CAPStartPatrol,{CapGroup,patrolObj},10)
    else
        env.info("Group could not be spawned.")
    end
end

function SpawnCAPBorder(difficulty)
    if difficulty == nil then
        local ds = {"Easy","Medium","Hard"}
        difficulty = ds[math.random(#ds)]
    end
    local base = CAPBorderAirbases[math.random(#CAPBorderAirbases)]
    local SpawnObj = Spawn_CAP[difficulty]
    local CapGroup = SpawnObj:SpawnAtAirbase(base)
end

Spawn_CAP["Easy"] = SPAWN:New("CAP Target Easy")
    :InitRandomizeTemplatePrefixes("Spawn CAP Easy")
    :InitCleanUp(120)
    :OnSpawnGroup(CAPOnSpawnGroup,CAPPatrolZonesBorder)
Spawn_CAP["Medium"] = SPAWN:New("CAP Target Medium")
    :InitRandomizeTemplatePrefixes("Spawn CAP Medium")
    :InitCleanUp(120)
    :OnSpawnGroup(CAPOnSpawnGroup,CAPPatrolZonesBorder)
Spawn_CAP["Hard"] = SPAWN:New("CAP Target Hard")
    :InitRandomizeTemplatePrefixes("Spawn CAP Hard")
    :InitCleanUp(120)
    :OnSpawnGroup(CAPOnSpawnGroup,CAPPatrolZonesBorder)

SetClientsActive = SET_CLIENT:New()
    :FilterCoalitions("blue")
    :FilterCategories("plane")
    :FilterActive()
    :FilterStart()
SetEnemyAir = SET_GROUP:New()
    :FilterPrefixes("CAP Target")
    :FilterActive(true):
    FilterStart()
CAPTestOffset = 0
function ScheduledDetectCAP()

    local ClientsActive = SetClientsActive:Count() + 3 + CAPTestOffset
    
    env.info("CAP Detect - Clients: "..ClientsActive)
    local CountEnemy = SetEnemyAir:Count()
    env.info("CAP Detect - CountEnemy: "..CountEnemy)
    local CountToSpawn = ClientsActive - CountEnemy
    env.info("CAP Detect - CountToSpawn: "..CountToSpawn)

    if CountToSpawn > 0 then
        SpawnCAPBorder()
    end
end
SCHEDULER:New(nil, ScheduledDetectCAP, {}, 0, 300, 0.6)

Spawn_CAP_RedBase = SPAWN:New("CAP Red Base")
    :InitRandomizeTemplatePrefixes( "Spawn CAP x2 Medium" )
    :InitRepeatOnEngineShutDown()
    :InitLimit(2,0)
    :InitCleanUp(120)
    :OnSpawnGroup(CAPOnSpawnGroup,CAPPatrolZonesBase)
    :SpawnScheduled(400,0.5)
    :SpawnScheduleStart()

--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Spawn Border CAP", MenuDebug, SpawnCAPBorder, "Medium")
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Spawn Base CAP", MenuDebug,function()
--    Spawn_CAP_RedBase:Spawn()
--end)
--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Increase detect offset", MenuDebug, function()
--    CAPTestOffset = CAPTestOffset + 1
--end)

env.info("Kickoff: CAP init done")

-- SAMs
env.info("Kickoff: SAM init start")
-- Base SAMs
local SamSpawnCountBase = 5
local ZoneSetBase = SET_ZONE:New():FilterPrefixes("Zone SAM Base"):FilterStart()
Spawn_SAM_Base = SPAWN:New( "SAM Target Base" )
    :InitRandomizeTemplatePrefixes( "Spawn SAM Hard" )
for i=1,SamSpawnCountBase do
    local zone = ZoneSetBase:GetRandom()
    ZoneSetBase:RemoveZonesByName(zone:GetName())
    Spawn_SAM_Base:SpawnInZone(zone,true)
end
-- Border SAMs
local SamSpawnCountBorder = 17
local ZoneSetBase = SET_ZONE:New():FilterPrefixes("Zone SAM Border"):FilterStart()
Spawn_SAM_Border = SPAWN:New( "SAM Target Border" )
    :InitRandomizeTemplatePrefixes( "Spawn SAM Border" )
for i=1,SamSpawnCountBorder do
    local zone = ZoneSetBase:GetRandom()
    ZoneSetBase:RemoveZonesByName(zone:GetName())
    Spawn_SAM_Border:SpawnInZone(zone)
end
env.info("Kickoff: SAM init done")

env.info("Kickoff: BAI Defense init start")

Ally_Groups = {}
Ally_Zones = {}
function SpawnBAIAllies(index)
    env.info("(Re)Spawning BAI Allies ("..index..")")
    env.info("Zone: "..Ally_Zones[index]:GetName())
    local AllyGroup = SPAWN:New("Ally Defense "..index)
        :InitRandomizeTemplatePrefixes("Spawn Ally Defense")
        :SpawnInZone(Ally_Zones[index],true)

    env.info("Group: "..AllyGroup:GetName())
    
    Ally_Groups[AllyGroup:GetName()] = index
    
    AllyGroup:HandleEvent(EVENTS.Dead)
    function AllyGroup:OnEventDead(EventData)
        local unitGroup = EventData.IniGroup
        local index = Ally_Groups[unitGroup:GetName()]
        if BAIAllies_Respawning[index] == false then
            if unitGroup:GetSize() <= 1 then
                env.info("Group respawning: Ally Defense "..index)
                BAIAllies_Respawning[index] = true
                SCHEDULER:New(nil,DestroyGroups,{"Ally Defense "..index},20)
                SCHEDULER:New(nil,SpawnBAIAllies,{index},180)
            end
        end
    end
    BAIAllies_Respawning[index] = false
end

BAIAllies_Respawning = {}
for i=1,4 do
    Ally_Zones[i] = ZONE:New("Zone Defense "..i)
    BAIAllies_Respawning[i] = false
    SpawnBAIAllies(i)
end

function BAIWaitForEngage(BaiGroup,AiBaiZone,PatrolZone,EngageZone)
    if BaiGroup:IsPartlyInZone(EngageZone) then
        env.info("BAI in engage zone")
        local bullsStr = BaiGroup:GetCoordinate():ToStringBULLS(coalition.side.BLUE)
        CommandCenter:MessageToCoalition("Friendly ground assets being engaged by hostile air at "..bullsStr.." - Defend our allies!")
        --AiBaiZone:__Accomplish(600)
        
        SCHEDULER:New(nil,function(AiBaiZone)
            env.info("BAI RTB")
            CommandCenter:MessageToCoalition("Hostile ground attack bugging out")
            AiBaiZone:__RTB(1)
        end,{AiBaiZone},600)
        
    else
        --env.info("BAI not in engage zone")
        SCHEDULER:New(nil,BAIWaitForEngage,{BaiGroup,AiBaiZone,PatrolZone,EngageZone},10)
    end
end
function BAIWaitForPatrol(BaiGroup,AiBaiZone,PatrolZone,EngageZone)
    if BaiGroup:IsPartlyInZone(PatrolZone) then
        env.info("BAI in patrol zone")
        local bullsStr = BaiGroup:GetCoordinate():ToStringBULLS(coalition.side.BLUE)
        CommandCenter:MessageToCoalition("Hostile ground attack aircraft detected inbound at "..bullsStr.." - Defend our allies!")
        AiBaiZone:__Engage(1)
        SCHEDULER:New(nil,BAIWaitForEngage,{BaiGroup,AiBaiZone,PatrolZone,EngageZone},10)
    else
        --env.info("BAI not in patrol zone")
        SCHEDULER:New(nil,BAIWaitForPatrol,{BaiGroup,AiBaiZone,PatrolZone,EngageZone},10)
    end
end
function BAIWaitForTakeoff(BaiGroup,AiBaiZone,PatrolZone,EngageZone)
    if BaiGroup:InAir() then
        env.info("BAI group starting: "..BaiGroup:GetName())
        AiBaiZone:__Start(1)
        SCHEDULER:New(nil,BAIWaitForPatrol,{BaiGroup,AiBaiZone,PatrolZone,EngageZone},10)
    else
        --env.info("BAI waiting for takeoff")
        SCHEDULER:New(nil,BAIWaitForTakeoff,{BaiGroup,AiBaiZone,PatrolZone,EngageZone},10)
    end
end
function BAIOnSpawnGroup(BaiGroup)
    local targetIndex = math.random(4)
    env.info("BAI target: "..targetIndex)
    local PatrolZone = ZONE:New("BAI Patrol Zone "..targetIndex)
    local EngageZone = ZONE:New("Zone Defense "..targetIndex)
    local AiBaiZone = AI_BAI_ZONE:New(PatrolZone,8000,10000,700,1200,EngageZone)
    AiBaiZone:SetControllable(BaiGroup)
        
    SCHEDULER:New(nil,BAIWaitForTakeoff,{BaiGroup,AiBaiZone,PatrolZone,EngageZone}, 10)
end
BAIAirbases = {
    AIRBASE:FindByName("Mineralnye Vody"),
    AIRBASE:FindByName("Mozdok"),
    AIRBASE:FindByName("Nalchik")
}
Spawn_BAI = SPAWN:New("BAI Target")
    :InitRandomizeTemplatePrefixes( "Spawn BAI" )
    :InitCleanUp(120)
    :InitLimit(6,0)
    :OnSpawnGroup(BAIOnSpawnGroup)
    
function SpawnBAI()
    local base = BAIAirbases[math.random(#BAIAirbases)]
    Spawn_BAI:SpawnAtAirbase(base)
end
SCHEDULER:New(nil,SpawnBAI,{},2400,2400,0.3)

--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Spawn BAI", MenuDebug,function()
--    SpawnBAI()
--end)

env.info("Kickoff: BAI Defense init done")

-- Support
env.info("Kickoff: Support init start")
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

Red_AWACS_Spawn = SPAWN:New("Red AWACS")
    :InitRepeatOnLanding()
    :InitLimit(1,0)
    :SpawnScheduled(60,0)
    :SpawnScheduleStart()

function JTACStartAutoLaseDelayed(jtac,code)
    env.info("New JTAC Spawned: "..jtac:GetName())
    SCHEDULER:New(nil, function(jtac,code)
        JTACAutoLase(jtac:GetName(), code)
    end,{jtac,code},120)
end

SPAWN:New("JTAC Easy")
    :InitLimit(1,0)
    :OnSpawnGroup(JTACStartAutoLaseDelayed,1688)
    :SpawnScheduled(60,0)
    :SpawnScheduleStart()
SPAWN:New("JTAC Medium")
    :InitLimit(1,0)
    :OnSpawnGroup(JTACStartAutoLaseDelayed,1687)
    :SpawnScheduled(60,0)
    :SpawnScheduleStart()

-- VIP
env.info("Kickoff: VIP init start")
local vipSpawns = {
    "VIP Target Nalchik",
    "VIP Target Mineralnye",
    "VIP Target Mozdok",
    "VIP Target Beslan"
}

local randomVip = math.random(#vipSpawns)
env.info("Vip selection: "..randomVip.."/"..#vipSpawns)
VipTarget = SPAWN:New(vipSpawns[randomVip])
    :InitUnControlled(true)
    :Spawn()

function MonitorVIPStatus()
    if VipTarget:GetUnit(1):GetLife() < 10 then
        MESSAGE:New("Vip transport confirmed to be neutralized, well done.",10,"Debug"):ToBlue()
        VIPScheduler:Stop()
    end
end

VIPScheduler = SCHEDULER:New(nil, MonitorVIPStatus, {}, 60, 60)

--MENU_COALITION_COMMAND:New( coalition.side.BLUE, "Destroy VIP target", MenuDebug,
--    function()
--        local unit = SET_UNIT:New():FilterPrefixes("VIP Target"):FilterStart():GetFirst()
--        unit:GetCoordinate():Explosion(10)
--    end
--)
env.info("Kickoff: VIP init done")

--GROUP:FindByName("Ship Practice"):PatrolRoute()

SCHEDULER:New(nil, function()
    MESSAGE:New("Mission restarting in 30 minutes",60,"Restart"):ToBlue()
end, {}, 13200)
SCHEDULER:New(nil, function()
    MESSAGE:New("Mission restarting in 5 minutes",60,"Restart"):ToBlue()
end, {}, 14700)
env.info("Kickoff: init done")
