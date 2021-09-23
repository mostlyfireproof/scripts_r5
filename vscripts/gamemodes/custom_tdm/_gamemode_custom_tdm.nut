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
    array<entity> entityModifications = []

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

        foreach (mod in file.entityModifications) {
            mod.Destroy()
            file.entityModifications.clear()
        }
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

void function _OnPlayerConnected(entity player)
{
    if(!IsValid(player)) return

    TpPlayerToSpawnPoint(player)
    player.UnfreezeControlsOnServer();
    //player.ForceStand()
    DecideRespawnPlayer(player, true)
}

void function _OnPlayerDied(entity victim, entity attacker, var damageInfo)
{
    DecideRespawnPlayer(victim, true)
    TpPlayerToSpawnPoint(victim)
    victim.UnfreezeControlsOnServer();
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

	entity result = CreateFRProp(file.currentModel, pos, angle, true, 10000)

    file.modifications.append(modelSerialized)
    file.entityModifications.append(result)

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
    // Model Serializer
    
    string serialized = ""
    
    int index = 0
    foreach (modelSerialized in file.modifications) {
        serialized += "m:" + modelSerialized
        if (index != (file.modifications.len() - 1)) {
            serialized += "|"
        }
        index++
    }

    printl("Serialization: " + serialized)
    
    return serialized
}

array<entity> function deserialize(string serialized) {
    array<string> sections = split(serialized, "|")
    array<entity> entities = []

    int index = 0
    foreach(section in sections) {
        index++

        bool isModelSection = startsWith(section, "m:")
        
        if (isModelSection) {
            string payload = StringReplace(section, "m:", "")

            array<string> payloadSections = split(section, ";")

            if (payloadSections.len() < 3) {
                printl("Problem with loading model: Less than 3 payloadSections " + payloadSections)
            }

            string modelName = payloadSections[0]
            vector origin = deserializeVector(payloadSections[1], "origin")
            vector angles = deserializeVector(payloadSections[2], "angles")
            
            entities.append(CreateFRProp(CastStringToAsset(modelName), origin, angles))
            printl("Loading model: " + modelName + " at " + origin + " with angle " + angles)
        } else {
            printl("Problem with section number " + index.tostring())
        }
    } 
    return entities
}

vector function deserializeVector(string serialized, string type) {
    array<string> axis = split(serialized, ",")

    try {
        float x = axis[0].tofloat()
        float y = axis[1].tofloat()
        float z = axis[2].tofloat()
        return <x, y, z>
    } catch(error) {
        printl("Failed to serialize vector " + type + " " + serialized)
        printl(error)
        return <0, 0, 0>
    }
}

bool function ClientCommand_Compile(entity player, array<string> args) {
    printl("SERIALIZED: " + serialize())
    return true
}

bool function ClientCommand_Load(entity player, array<string> args) {
    if (args.len() == 0) {
        printl("USAGE: load <serialized code>")
        return false
    }

    string serializedCode = args[0]
    file.entityModifications = deserialize(serializedCode)
    return true
}