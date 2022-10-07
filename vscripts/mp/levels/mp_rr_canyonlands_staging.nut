global function CodeCallback_MapInit

void function CodeCallback_MapInit()
{
    PrecacheModel( MU1_LEVIATHAN_MODEL )
    Canyonlands_MapInit_Common()

    #if SERVER
        SpawnEditorProps()
    #endif
}

#if SERVER
// Creates a prop as a map element
entity function CreateEditorProp(asset a, vector pos, vector ang, bool mantle = false, float fade = 2000, 
int realm = -1)
{
    entity e = CreatePropDynamic(a,pos,ang,SOLID_VPHYSICS,fade)
    e.kv.fadedist = fade
    if(mantle) e.AllowMantle()

    if (realm > -1) {
        e.RemoveFromAllRealms()
        e.AddToRealm(realm)
    }

    string positionSerialized = pos.x.tostring() + "," + pos.y.tostring() + "," + pos.z.tostring()
    string anglesSerialized = ang.x.tostring() + "," + ang.y.tostring() + "," + ang.z.tostring()

    e.SetScriptName("editor_placed_prop")
    e.e.gameModeId = realm
    printl("[editor]" + string(a) + ";" + positionSerialized + ";" + anglesSerialized + ";" + realm)

    return e
}

// Creates a zipline as a map element
void function CreateEditorZipline( vector startPos, vector endPos )
{
	string startpointName = UniqueString( "rope_startpoint" )
	string endpointName = UniqueString( "rope_endpoint" )

	entity rope_start = CreateEntity( "move_rope" )
	SetEditorTargetName( rope_start, startpointName )
	rope_start.kv.NextKey = endpointName
	rope_start.kv.MoveSpeed = 64
	rope_start.kv.Slack = 25
	rope_start.kv.Subdiv = "2"
	rope_start.kv.Width = "3"
	rope_start.kv.Type = "0"
	rope_start.kv.TextureScale = "1"
	rope_start.kv.RopeMaterial = "cable/zipline.vmt"
	rope_start.kv.PositionInterpolator = 2
	rope_start.kv.Zipline = "1"
	rope_start.kv.ZiplineAutoDetachDistance = "150"
	rope_start.kv.ZiplineSagEnable = "0"
	rope_start.kv.ZiplineSagHeight = "50"
	rope_start.SetOrigin( startPos )

	entity rope_end = CreateEntity( "keyframe_rope" )
	SetEditorTargetName( rope_end, endpointName )
	rope_end.kv.MoveSpeed = 64
	rope_end.kv.Slack = 25
	rope_end.kv.Subdiv = "2"
	rope_end.kv.Width = "3"
	rope_end.kv.Type = "0"
	rope_end.kv.TextureScale = "1"
	rope_end.kv.RopeMaterial = "cable/zipline.vmt"
	rope_end.kv.PositionInterpolator = 2
	rope_end.kv.Zipline = "1"
	rope_end.kv.ZiplineAutoDetachDistance = "150"
	rope_end.kv.ZiplineSagEnable = "0"
	rope_end.kv.ZiplineSagHeight = "50"
	rope_end.SetOrigin( endPos )

	DispatchSpawn( rope_start )
	DispatchSpawn( rope_end )

	printl("[zipline][1]" + startPos)
	printl("[zipline][2]" + endPos)
}

void function SetEditorTargetName( entity ent, string name )
{
	ent.SetValueForKey( "targetname", name )
}
#endif

void function SpawnEditorProps()
{
    // Written by mostly fireproof. Let me know if there are any issues!
    printl("---- NEW EDITOR DATA ----")
    
}
