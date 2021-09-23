global function _CustomTDM_Init
global function _RegisterLocation

// constants to snap objects to a grid
const int POS_SNAP = 16
const int ANGLE_SNAP = 45

enum eTDMState
{
	IN_PROGRESS = 0
	WINNER_DECIDED = 1
}

struct {
    int tdmState = eTDMState.IN_PROGRESS
    array<entity> playerSpawnedProps
    LocationSettings& selectedLocation

    array<LocationSettings> locationSettings


    array<string> whitelistedWeapons

    entity bubbleBoundary
    entity currentEditor = null
    entity latestModification = null
    array<string> modifications = []

    float offsetZ = 0
    asset currentModel = $"mdl/error.rmdl"
    string currentModelName = "mdl/error.rmdl"
} file;


void function _CustomTDM_Init()
{
    AddCallback_OnClientConnected( void function(entity player) { thread _OnPlayerConnected(player) } )
    AddCallback_OnPlayerKilled(void function(entity victim, entity attacker, var damageInfo) {thread _OnPlayerDied(victim, attacker, damageInfo)})

    AddClientCommandCallback("editor", ClientCommand_Editor)
    AddClientCommandCallback("model", ClientCommand_Model)
    AddClientCommandCallback("compile", ClientCommand_Compile)
    AddClientCommandCallback("load", ClientCommand_Load)

    // Client side callbacks
    AddClientCommandCallback("place", OnAttack)
    AddClientCommandCallback("moveUp", ClientCommand_UP)
    AddClientCommandCallback("moveDown", ClientCommand_DOWN)

    //thread RunTDM()

    PrecacheModel(file.currentModel)
    int index = 0
    foreach(as in GetAssets()) {
        //printl("Index: " + index.tostring())
        PrecacheModel(as)
        index++
    }
}

bool function ClientCommand_TP(entity player, array<string> args) {
	if (args.len() > 3) return false

	int x = args[0].tointeger()
	int y = args[1].tointeger()
	int z = args[2].tointeger()

	player.SetOrigin(<x, y, z>)
	return true
}

void function _RegisterLocation(LocationSettings locationSettings)
{
    file.locationSettings.append(locationSettings)
}

LocPair function _GetVotingLocation()
{
    switch(GetMapName())
    {
        case "mp_rr_canyonlands_staging":
            return NewLocPair(<26794, -6241, -27479>, <0, 0, 0>)
        case "mp_rr_canyonlands_64k_x_64k":
        case "mp_rr_canyonlands_mu1":
        case "mp_rr_canyonlands_mu1_night":
            return NewLocPair(<-6252, -16500, 3296>, <0, 0, 0>)
        case "mp_rr_desertlands_64k_x_64k":
        case "mp_rr_desertlands_64k_x_64k_nx":
            return NewLocPair(<1763, 5463, -3145>, <5, -95, 0>)
        default:
            Assert(false, "No voting location for the map!")
    }
    unreachable
}

void function _OnPropDynamicSpawned(entity prop)
{
    file.playerSpawnedProps.append(prop)

}

void function DestroyPlayerProps()
{
    foreach(prop in file.playerSpawnedProps)
    {
        if(IsValid(prop))
            prop.Destroy()
    }
    file.playerSpawnedProps.clear()
}

void function ScreenFadeToFromBlack(entity player, float fadeTime = 1, float holdTime = 1)
{
    if( IsValid( player ) )
        ScreenFadeToBlack(player, fadeTime / 2, holdTime / 2)
    wait fadeTime
    if( IsValid( player ) )
        ScreenFadeFromBlack(player, fadeTime / 2, holdTime / 2)
}

bool function ClientCommand_UP(entity player, array<string> args)
{
    file.offsetZ += 2
    return true
}

bool function ClientCommand_DOWN(entity player, array<string> args)
{
    file.offsetZ -= 2
    return true
}

bool function ClientCommand_Editor(entity player, array<string> args) {
	if (file.currentEditor != null) {
		file.currentEditor = null
		file.latestModification.Destroy()
		file.latestModification = null
		return true
	}
	file.currentEditor = player
	thread StartEditorTask()
	return true
}

bool function ClientCommand_Model(entity player, array<string> args) {
	if (args.len() < 1) {
		return false
	}

	try {
		string modelName = args[0]
	  file.currentModel = CastStringToAsset(modelName)
		file.currentModelName = modelName
  } catch (error) {
		printl(error)
	}
	return true
}

bool function ClientCommand_Cache(entity player, array<string> args) {
	if (args.len() < 1) {
		return false
	}

	string modelName = args[0]
	PrecacheModel(CastStringToAsset(modelName))
	return true
}

bool function ClientCommand_GiveWeapon(entity player, array<string> args)
{
    if(args.len() < 2) return false;

    bool foundMatch = false


    foreach(weaponName in file.whitelistedWeapons)
    {
        if(args[1] == weaponName)
        {
            foundMatch = true
            break
        }
    }

    if(file.whitelistedWeapons.find(args[1]) == -1 && file.whitelistedWeapons.len()) return false

    entity weapon

    try {
        entity primary = player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_0 )
        entity secondary = player.GetNormalWeapon( WEAPON_INVENTORY_SLOT_PRIMARY_1 )
        entity tactical = player.GetOffhandWeapon( OFFHAND_TACTICAL )
        entity ultimate = player.GetOffhandWeapon( OFFHAND_ULTIMATE )
        switch(args[0])
        {
            case "p":
            case "primary":
                if( IsValid( primary ) ) player.TakeWeaponByEntNow( primary )
                weapon = player.GiveWeapon(args[1], WEAPON_INVENTORY_SLOT_PRIMARY_0)
                break
            case "s":
            case "secondary":
                if( IsValid( secondary ) ) player.TakeWeaponByEntNow( secondary )
                weapon = player.GiveWeapon(args[1], WEAPON_INVENTORY_SLOT_PRIMARY_1)
                break
            case "t":
            case "tactical":
                if( IsValid( tactical ) ) player.TakeOffhandWeapon( OFFHAND_TACTICAL )
                weapon = player.GiveOffhandWeapon(args[1], OFFHAND_TACTICAL)
                break
            case "u":
            case "ultimate":
                if( IsValid( ultimate ) ) player.TakeOffhandWeapon( OFFHAND_ULTIMATE )
                weapon = player.GiveOffhandWeapon(args[1], OFFHAND_ULTIMATE)
                break
        }
    }
    catch( e1 ) { }

    if( args.len() > 2 )
    {
        try {
            weapon.SetMods(args.slice(2, args.len()))
        }
        catch( e2 ) {
            print(e2)
        }
    }

    if( IsValid( weapon) && !weapon.IsWeaponOffhand() ) player.SetActiveWeaponBySlot(eActiveInventorySlot.mainHand, GetSlotForWeapon(player, weapon))
    return true

}



void function _OnPlayerConnected(entity player)
{
    if(!IsValid(player)) return

    TpPlayerToSpawnPoint(player)
    player.UnfreezeControlsOnServer();
}

void function _OnPlayerDied(entity victim, entity attacker, var damageInfo)
{
    DecideRespawnPlayer(victim, true)
    TpPlayerToSpawnPoint(victim)
    victim.UnfreezeControlsOnServer();
}

entity function CreateBubbleBoundary(LocationSettings location)
{
    array<LocPair> spawns = location.spawns

    vector bubbleCenter
    foreach(spawn in spawns)
    {
        bubbleCenter += spawn.origin
    }

    bubbleCenter /= spawns.len()

    float bubbleRadius = 0

    foreach(LocPair spawn in spawns)
    {
        if(Distance(spawn.origin, bubbleCenter) > bubbleRadius)
        bubbleRadius = Distance(spawn.origin, bubbleCenter)
    }

    bubbleRadius += GetCurrentPlaylistVarFloat("bubble_radius_padding", 99999)

    entity bubbleShield = CreateEntity( "prop_dynamic" )
	bubbleShield.SetValueForModelKey( BUBBLE_BUNKER_SHIELD_COLLISION_MODEL )
    bubbleShield.SetOrigin(bubbleCenter)
    bubbleShield.SetModelScale(bubbleRadius / 235)
    bubbleShield.kv.CollisionGroup = 0
    bubbleShield.kv.rendercolor = "127 73 37"
    DispatchSpawn( bubbleShield )



    thread MonitorBubbleBoundary(bubbleShield, bubbleCenter, bubbleRadius)


    return bubbleShield

}


void function MonitorBubbleBoundary(entity bubbleShield, vector bubbleCenter, float bubbleRadius)
{
    while(IsValid(bubbleShield))
    {

        foreach(player in GetPlayerArray_Alive())
        {
            if(!IsValid(player)) continue
            if(Distance(player.GetOrigin(), bubbleCenter) > bubbleRadius)
            {
				Remote_CallFunction_Replay( player, "ServerCallback_PlayerTookDamage", 0, 0, 0, 0, DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, eDamageSourceId.deathField, null )
                //player.TakeDamage( int( Deathmatch_GetOOBDamagePercent() / 100 * float( player.GetMaxHealth() ) ), null, null, { scriptType = DF_BYPASS_SHIELD | DF_DOOMED_HEALTH_LOSS, damageSourceId = eDamageSourceId.deathField } )
            }
        }
        wait 1
    }

}


void function PlayerRestoreHP(entity player, float health, float shields)
{
    player.SetHealth( health )
    Inventory_SetPlayerEquipment(player, "helmet_pickup_lv4_abilities", "helmet")

    if(shields == 0) return;
    else if(shields <= 50)
        Inventory_SetPlayerEquipment(player, "armor_pickup_lv1", "armor")
    else if(shields <= 75)
        Inventory_SetPlayerEquipment(player, "armor_pickup_lv2", "armor")
    else if(shields <= 100)
        Inventory_SetPlayerEquipment(player, "armor_pickup_lv3", "armor")
    player.SetShieldHealth( shields )

}

void function GrantSpawnImmunity(entity player, float duration)
{
    if(!IsValid(player)) return;
    MakeInvincible(player)
    wait duration
    if(!IsValid(player)) return;
    ClearInvincible(player)
}


vector function GetClosestEnemyToOrigin(vector origin, int ourTeam)
{
    float minDist = -1
    vector enemyOrigin = <0, 0, 0>

    foreach(player in GetPlayerArray_Alive())
    {
        if(player.GetTeam() == ourTeam) continue

        float dist = Distance(player.GetOrigin(), origin)
        if(dist < minDist || minDist < 0)
        {
            minDist = dist
            enemyOrigin = player.GetOrigin()
        }
    }

    return enemyOrigin
}

void function StartEditorTask() {
	while(file.currentEditor != null) {
		SpawnFakeModelAtCrosshair(file.currentEditor, file.currentModel)
		WaitFrame()
	}
}

void function SpawnFakeModelAtCrosshair(entity editor, asset model) {
	if (file.latestModification != null) {
		file.latestModification.Destroy()
	}

	vector originOG = GetPlayerCrosshairOrigin(editor)
	//origin.z += file.offsetZ
	vector rotationOG = editor.GetAngles()

    vector origin = snapVec(originOG, POS_SNAP)
    vector rotation = snapVec(rotationOG, ANGLE_SNAP)

	file.latestModification = CreatePropDynamic(model, origin + <0.0, 0.0, file.offsetZ>, rotation)
    // file.latestModification.kv.rendercolor = "50 50 200" doesn't work  :(
}

void function CreatePermanentModel(entity editor) {
    // Modified to be able to snap by default to position and angle
    entity model = file.latestModification
    vector posOG = model.GetOrigin()
	vector angleOG = model.GetAngles()

	vector pos = snapVec(posOG, POS_SNAP)
	vector angle = snapVec(angleOG, ANGLE_SNAP)

	string positionSerialized = pos.x.tostring() + "," + pos.y.tostring() + "," + pos.z.tostring()
	string anglesSerialized = angle.x.tostring() + "," + angle.y.tostring() + "," + angle.z.tostring()
	string modelSerialized = file.currentModelName + ";" + positionSerialized + ";" + anglesSerialized

	printl("[editor] " + modelSerialized)

	CreateFRProp(file.currentModel, pos, angle, true, 10000)

    file.modifications.append(modelSerialized)

	file.latestModification.Destroy()
	file.latestModification = null
}

void function TpPlayerToSpawnPoint(entity player)
{

	LocPair loc = _GetVotingLocation()

    player.SetOrigin(loc.origin)
    player.SetAngles(loc.angles)

    PutEntityInSafeSpot( player, null, null, player.GetOrigin() + <0,0,128>, player.GetOrigin() )
}

bool function OnAttack(entity player, array<string> args) {
	if (file.currentEditor != null) {
		CreatePermanentModel(player)
		return true
	}
	return false
}

entity function CreateFRProp(asset a, vector pos, vector ang, bool mantle = false, float fade = 2000)
{

	entity e = CreatePropDynamic(a,pos,ang,SOLID_VPHYSICS,15000)
	e.kv.fadedist = fade
	if(mantle) e.AllowMantle()
	return e
}

asset function CastStringToAsset( string val ) {
	return GetKeyValueAsAsset( {kn = val}, "kn")
}

// Snaps a number to the nearest size
int function snapTo( float f, int size ) {
    return ((f / size).tointeger()) * size
}

// Snaps a vector to the grid of size
vector function snapVec( vector vec, int size  ) {
    int x = snapTo(vec.x, size)
    int y = snapTo(vec.y, size)
    int z = snapTo(vec.z, size)

    return <x,y,z>
}

string function serialize() {
    return ""
}

array<string> function deserialize() {
    return []
}

bool function ClientCommand_Compile(entity player, array<string> args) {
    return true
}

bool function ClientCommand_Load(entity player, array<string> args) {
    return true
}