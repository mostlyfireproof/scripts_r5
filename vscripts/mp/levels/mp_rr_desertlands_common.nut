    global function Desertlands_PreMapInit_Common
global function Desertlands_MapInit_Common
global function CodeCallback_PlayerEnterUpdraftTrigger
global function CodeCallback_PlayerLeaveUpdraftTrigger

#if SERVER
global function Desertlands_MU1_MapInit_Common
global function Desertlands_MU1_EntitiesLoaded_Common
global function Desertlands_MU1_UpdraftInit_Common
global function Desertlands_SetTrainEnabled
#endif


#if SERVER
//Copied from _jump_pads. This is being hacked for the geysers.
const float JUMP_PAD_PUSH_RADIUS = 256.0
const float JUMP_PAD_PUSH_PROJECTILE_RADIUS = 32.0//98.0
const float JUMP_PAD_PUSH_VELOCITY = 2000.0
const float JUMP_PAD_VIEW_PUNCH_SOFT = 25.0
const float JUMP_PAD_VIEW_PUNCH_HARD = 4.0
const float JUMP_PAD_VIEW_PUNCH_RAND = 4.0
const float JUMP_PAD_VIEW_PUNCH_SOFT_TITAN = 120.0
const float JUMP_PAD_VIEW_PUNCH_HARD_TITAN = 20.0
const float JUMP_PAD_VIEW_PUNCH_RAND_TITAN = 20.0
const TEAM_JUMPJET_DBL = $"P_team_jump_jet_ON_trails"
const ENEMY_JUMPJET_DBL = $"P_enemy_jump_jet_ON_trails"
const asset JUMP_PAD_MODEL = $"mdl/props/octane_jump_pad/octane_jump_pad.rmdl"

const float JUMP_PAD_ANGLE_LIMIT = 0.70
const float JUMP_PAD_ICON_HEIGHT_OFFSET = 48.0
const float JUMP_PAD_ACTIVATION_TIME = 0.5
const asset JUMP_PAD_LAUNCH_FX = $"P_grndpnd_launch"
const JUMP_PAD_DESTRUCTION = "jump_pad_destruction"

// Loot drones
const int NUM_LOOT_DRONES_TO_SPAWN = 12
const int NUM_LOOT_DRONES_WITH_VAULT_KEYS = 4
#endif

struct
{
	#if SERVER
	bool isTrainEnabled = true
	#endif
} file

void function Desertlands_PreMapInit_Common()
{
	//DesertlandsTrain_PreMapInit()
}

void function Desertlands_MapInit_Common()
{
	printt( "Desertlands_MapInit_Common" )

	MapZones_RegisterDataTable( $"datatable/map_zones/zones_mp_rr_desertlands_64k_x_64k.rpak" )

	FlagInit( "PlayConveyerStartFX", true )

	SetVictorySequencePlatformModel( $"mdl/rocks/desertlands_victory_platform.rmdl", < 0, 0, -10 >, < 0, 0, 0 > )

	#if SERVER
		//%if HAS_LOOT_DRONES && HAS_LOOT_ROLLERS
		InitLootDrones()
		InitLootRollers()
		//%endif

		AddCallback_EntitiesDidLoad( EntitiesDidLoad )

		SURVIVAL_SetPlaneHeight( 15250 )
		SURVIVAL_SetAirburstHeight( 2500 )
		SURVIVAL_SetMapCenter( <0, 0, 0> )
		//Survival_SetMapFloorZ( -8000 )

		//if ( file.isTrainEnabled )
		//	DesertlandsTrain_Precaches()

		AddSpawnCallback_ScriptName( "desertlands_train_mover_0", AddTrainToMinimap )

		SpawnEditorProps()
	#endif

	#if CLIENT
		Freefall_SetPlaneHeight( 15250 )
		Freefall_SetDisplaySeaHeightForLevel( -8961.0 )

		SetVictorySequenceLocation( <11092.6162, -20878.0684, 1561.52222>, <0, 267.894653, 0> )
		SetVictorySequenceSunSkyIntensity( 1.0, 0.5 )
		SetMinimapBackgroundTileImage( $"overviews/mp_rr_canyonlands_bg" )

		// RegisterMinimapPackage( "prop_script", eMinimapObject_prop_script.TRAIN, MINIMAP_OBJECT_RUI, MinimapPackage_Train, FULLMAP_OBJECT_RUI, FullmapPackage_Train )
	#endif
}

#if SERVER
void function EntitiesDidLoad()
{
	#if SERVER && DEV
		test_runmapchecks()
	#endif

	GeyserInit()
	Updrafts_Init()

	InitLootDronePaths()

	string currentPlaylist = GetCurrentPlaylistName()
	// thread SpawnLootDrones( GetPlaylistVarInt( currentPlaylist, "loot_drones_spawn_count", NUM_LOOT_DRONES_TO_SPAWN ) )

	int keyCount = GetPlaylistVarInt( currentPlaylist, "loot_drones_vault_key_count", NUM_LOOT_DRONES_WITH_VAULT_KEYS )
	//if ( keyCount > 0 )
	//	LootRollers_ForceAddLootRefToRandomLootRollers( "data_knife", keyCount )

	if ( file.isTrainEnabled )
		thread DesertlandsTrain_Init()
}
#endif

#if SERVER
void function Desertlands_SetTrainEnabled( bool enabled )
{
	file.isTrainEnabled = enabled
}
#endif

//=================================================================================================
//=================================================================================================
//
//  ##     ## ##     ##    ##       ######   #######  ##     ## ##     ##  #######  ##    ##
//  ###   ### ##     ##  ####      ##    ## ##     ## ###   ### ###   ### ##     ## ###   ##
//  #### #### ##     ##    ##      ##       ##     ## #### #### #### #### ##     ## ####  ##
//  ## ### ## ##     ##    ##      ##       ##     ## ## ### ## ## ### ## ##     ## ## ## ##
//  ##     ## ##     ##    ##      ##       ##     ## ##     ## ##     ## ##     ## ##  ####
//  ##     ## ##     ##    ##      ##    ## ##     ## ##     ## ##     ## ##     ## ##   ###
//  ##     ##  #######   ######     ######   #######  ##     ## ##     ##  #######  ##    ##
//
//=================================================================================================
//=================================================================================================

#if SERVER
void function Desertlands_MU1_MapInit_Common()
{
	AddSpawnCallback_ScriptName( "conveyor_rotator_mover", OnSpawnConveyorRotatorMover )

	Desertlands_MapInit_Common()
	PrecacheParticleSystem( JUMP_PAD_LAUNCH_FX )

	//SURVIVAL_SetDefaultLootZone( "zone_medium" )

	//LaserMesh_Init()
	FlagSet( "DisableDropships" )

	AddDamageCallbackSourceID( eDamageSourceId.burn, OnBurnDamage )

	svGlobal.evacEnabled = false //Need to disable this on a map level if it doesn't support it at all
}


void function OnBurnDamage( entity player, var damageInfo )
{
	if ( !player.IsPlayer() )
		return

	// sky laser shouldn't hurt players in plane
	if ( player.GetPlayerNetBool( "playerInPlane" ) )
	{
		DamageInfo_SetDamage( damageInfo, 0 )
	}
}

///////////////////////
///////////////////////
//// Conveyor


void function OnSpawnConveyorRotatorMover( entity mover )
{
	thread ConveyorRotatorMoverThink( mover )
}


void function ConveyorRotatorMoverThink( entity mover )
{
	mover.EndSignal( "OnDestroy" )

	entity rotator = GetEntByScriptName( "conveyor_rotator" )
	entity startNode
	entity endNode

	array<entity> links = rotator.GetLinkEntArray()
	foreach ( l in links )
	{
		if ( l.GetValueForKey( "script_noteworthy" ) == "end" )
			endNode = l
		if ( l.GetValueForKey( "script_noteworthy" ) == "start" )
			startNode = l
	}


	float angle1 = VectorToAngles( startNode.GetOrigin() - rotator.GetOrigin() ).y
	float angle2 = VectorToAngles( endNode.GetOrigin() - rotator.GetOrigin() ).y

	float angleDiff = angle1 - angle2
	angleDiff = (angleDiff + 180) % 360 - 180

	float rotatorSpeed = float( rotator.GetValueForKey( "rotate_forever_speed" ) )
	float waitTime     = fabs( angleDiff ) / rotatorSpeed

	Assert( IsValid( endNode ) )

	while ( 1 )
	{
		mover.WaitSignal( "ReachedPathEnd" )

		mover.SetParent( rotator, "", true )

		wait waitTime

		mover.ClearParent()
		mover.SetOrigin( endNode.GetOrigin() )
		mover.SetAngles( endNode.GetAngles() )

		thread MoverThink( mover, [ endNode ] )
	}
}


void function Desertlands_MU1_UpdraftInit_Common( entity player )
{
	//ApplyUpdraftModUntilTouchingGround( player )
	thread PlayerSkydiveFromCurrentPosition( player )
	thread BurnPlayerOverTime( player )
}


void function Desertlands_MU1_EntitiesLoaded_Common()
{
	GeyserInit()
	Updrafts_Init()
}


//Geyster stuff
void function GeyserInit()
{
	array<entity> geyserTargets = GetEntArrayByScriptName( "geyser_jump" )
	foreach ( target in geyserTargets )
	{
		thread GeyersJumpTriggerArea( target )
		//target.Destroy()
	}
}


void function GeyersJumpTriggerArea( entity jumpPad )
{
	Assert ( IsNewThread(), "Must be threaded off" )
	jumpPad.EndSignal( "OnDestroy" )

	vector origin = OriginToGround( jumpPad.GetOrigin() )
	vector angles = jumpPad.GetAngles()

	entity trigger = CreateEntity( "trigger_cylinder_heavy" )
	SetTargetName( trigger, "geyser_trigger" )
	trigger.SetOwner( jumpPad )
	trigger.SetRadius( JUMP_PAD_PUSH_RADIUS )
	trigger.SetAboveHeight( 32 )
	trigger.SetBelowHeight( 16 ) //need this because the player or jump pad can sink into the ground a tiny bit and we check player feet not half height
	trigger.SetOrigin( origin )
	trigger.SetAngles( angles )
	trigger.SetTriggerType( TT_JUMP_PAD )
	trigger.SetLaunchScaleValues( JUMP_PAD_PUSH_VELOCITY, 1.25 )
	trigger.SetViewPunchValues( JUMP_PAD_VIEW_PUNCH_SOFT, JUMP_PAD_VIEW_PUNCH_HARD, JUMP_PAD_VIEW_PUNCH_RAND )
	trigger.SetLaunchDir( <0.0, 0.0, 1.0> )
	trigger.UsePointCollision()
	trigger.kv.triggerFilterNonCharacter = "0"
	DispatchSpawn( trigger )
	trigger.SetEnterCallback( Geyser_OnJumpPadAreaEnter )

	// entity traceBlocker = CreateTraceBlockerVolume( trigger.GetOrigin(), 24.0, true, CONTENTS_BLOCK_PING | CONTENTS_NOGRAPPLE, TEAM_MILITIA, GEYSER_PING_SCRIPT_NAME )
	// traceBlocker.SetBox( <-192, -192, -16>, <192, 192, 3000> )

	//DebugDrawCylinder( origin, < -90, 0, 0 >, JUMP_PAD_PUSH_RADIUS, trigger.GetAboveHeight(), 255, 0, 255, true, 9999.9 )
	//DebugDrawCylinder( origin, < -90, 0, 0 >, JUMP_PAD_PUSH_RADIUS, -trigger.GetBelowHeight(), 255, 0, 255, true, 9999.9 )

	OnThreadEnd(
		function() : ( trigger )
		{
			trigger.Destroy()
		} )

	WaitForever()
}


void function Geyser_OnJumpPadAreaEnter( entity trigger, entity ent )
{
	Geyser_JumpPadPushEnt( trigger, ent, trigger.GetOrigin(), trigger.GetAngles() )
}


void function Geyser_JumpPadPushEnt( entity trigger, entity ent, vector origin, vector angles )
{
	if ( Geyser_JumpPad_ShouldPushPlayerOrNPC( ent ) )
	{
		if ( ent.IsPlayer() )
		{
			entity jumpPad = trigger.GetOwner()
			if ( IsValid( jumpPad ) )
			{
				int fxId = GetParticleSystemIndex( JUMP_PAD_LAUNCH_FX )
				StartParticleEffectOnEntity( jumpPad, fxId, FX_PATTACH_ABSORIGIN_FOLLOW, 0 )
			}
			thread Geyser_JumpJetsWhileAirborne( ent )
		}
		else
		{
			EmitSoundOnEntity( ent, "JumpPad_LaunchPlayer_3p" )
			EmitSoundOnEntity( ent, "JumpPad_AirborneMvmt_3p" )
		}
	}
}


void function Geyser_JumpJetsWhileAirborne( entity player )
{
	if ( !IsPilot( player ) )
		return
	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	player.Signal( "JumpPadStart" )
	player.EndSignal( "JumpPadStart" )
	player.EnableSlowMo()
	player.DisableMantle()

	EmitSoundOnEntityExceptToPlayer( player, player, "JumpPad_LaunchPlayer_3p" )
	EmitSoundOnEntityExceptToPlayer( player, player, "JumpPad_AirborneMvmt_3p" )

	array<entity> jumpJetFXs
	array<string> attachments = [ "vent_left", "vent_right" ]
	int team                  = player.GetTeam()
	foreach ( attachment in attachments )
	{
		int friendlyID    = GetParticleSystemIndex( TEAM_JUMPJET_DBL )
		entity friendlyFX = StartParticleEffectOnEntity_ReturnEntity( player, friendlyID, FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( attachment ) )
		friendlyFX.SetOwner( player )
		SetTeam( friendlyFX, team )
		friendlyFX.kv.VisibilityFlags = ENTITY_VISIBLE_TO_FRIENDLY
		jumpJetFXs.append( friendlyFX )

		int enemyID    = GetParticleSystemIndex( ENEMY_JUMPJET_DBL )
		entity enemyFX = StartParticleEffectOnEntity_ReturnEntity( player, enemyID, FX_PATTACH_POINT_FOLLOW, player.LookupAttachment( attachment ) )
		SetTeam( enemyFX, team )
		enemyFX.kv.VisibilityFlags = ENTITY_VISIBLE_TO_ENEMY
		jumpJetFXs.append( enemyFX )
	}

	OnThreadEnd(
		function() : ( jumpJetFXs, player )
		{
			foreach ( fx in jumpJetFXs )
			{
				if ( IsValid( fx ) )
					fx.Destroy()
			}

			if ( IsValid( player ) )
			{
				player.DisableSlowMo()
				player.EnableMantle()
				StopSoundOnEntity( player, "JumpPad_AirborneMvmt_3p" )
			}
		}
	)

	WaitFrame()

	wait 0.1
	//thread PlayerSkydiveFromCurrentPosition( player )
	while( !player.IsOnGround() )
	{
		WaitFrame()
	}

}


bool function Geyser_JumpPad_ShouldPushPlayerOrNPC( entity target )
{
	if ( target.IsTitan() )
		return false

	if ( IsSuperSpectre( target ) )
		return false

	if ( IsTurret( target ) )
		return false

	if ( IsDropship( target ) )
		return false

	return true
}


///////////////////////
///////////////////////
//// Updrafts

const string UPDRAFT_TRIGGER_SCRIPT_NAME = "skydive_dust_devil"
void function Updrafts_Init()
{
	array<entity> triggers = GetEntArrayByScriptName( UPDRAFT_TRIGGER_SCRIPT_NAME )
	foreach ( entity trigger in triggers )
	{
		if ( trigger.GetClassName() != "trigger_updraft" )
		{
			entity newTrigger = CreateEntity( "trigger_updraft" )
			newTrigger.SetOrigin( trigger.GetOrigin() )
			newTrigger.SetAngles( trigger.GetAngles() )
			newTrigger.SetModel( trigger.GetModelName() )
			newTrigger.SetScriptName( UPDRAFT_TRIGGER_SCRIPT_NAME )
			newTrigger.kv.triggerFilterTeamBeast = 1
			newTrigger.kv.triggerFilterTeamNeutral = 1
			newTrigger.kv.triggerFilterTeamOther = 1
			newTrigger.kv.triggerFilterUseNew = 1
			DispatchSpawn( newTrigger )
			trigger.Destroy()
		}
	}
}

void function BurnPlayerOverTime( entity player )
{
	Assert( IsValid( player ) )
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "OnDeath" )
	player.EndSignal( "DeathTotem_PreRecallPlayer" )
	for ( int i = 0; i < 8; ++i )
	{
		//if ( !player.Player_IsInsideUpdraftTrigger() )
		//	break

		if ( !player.IsPhaseShifted() )
		{
			player.TakeDamage( 5, null, null, { damageSourceId = eDamageSourceId.burn, damageType = DMG_BURN } )
		}

		wait 0.5
	}
}
#endif

void function CodeCallback_PlayerEnterUpdraftTrigger( entity trigger, entity player )
{
	float entZ = player.GetOrigin().z
	//OnEnterUpdraftTrigger( trigger, player, max( -5750.0, entZ - 400.0 ) )
}


void function CodeCallback_PlayerLeaveUpdraftTrigger( entity trigger, entity player )
{
	//OnLeaveUpdraftTrigger( trigger, player )
}

#if SERVER
void function AddTrainToMinimap( entity mover )
{
	entity minimapObj = CreatePropScript( $"mdl/dev/empty_model.rmdl", mover.GetOrigin() )
	minimapObj.Minimap_SetCustomState( eMinimapObject_prop_script.TRAIN )
	minimapObj.SetParent( mover )
	SetTargetName( minimapObj, "trainIcon" )
	foreach ( player in GetPlayerArray() )
	{
		minimapObj.Minimap_AlwaysShow( 0, player )
	}
}
#endif

#if CLIENT
void function MinimapPackage_Train( entity ent, var rui )
{
	#if DEV
		printt( "Adding 'rui/hud/gametype_icons/sur_train_minimap' icon to minimap" )
	#endif
	RuiSetImage( rui, "defaultIcon", $"rui/hud/gametype_icons/sur_train_minimap" )
	RuiSetImage( rui, "clampedDefaultIcon", $"" )
	RuiSetBool( rui, "useTeamColor", false )
}

void function FullmapPackage_Train( entity ent, var rui )
{
	MinimapPackage_Train( ent, rui )
	RuiSetFloat2( rui, "iconScale", <1.5,1.5,0.0> )
	RuiSetFloat3( rui, "iconColor", <0.5,0.5,0.5> )
}
#endif

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



#if SERVER
// Spawns all the props
void function SpawnEditorProps()
{
    // Written by mostly fireproof. Let me know if there are any issues!
    printl("---- NEW EDITOR DATA ----")

    ////////////////////////////////
    //// MW2 TERMINAL BY KORBOY ////
    ////////////////////////////////

    //Ground platform
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-5,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-700,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-1395,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-2090,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-2785,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-3480,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-4175,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-4870,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-5565,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-6260,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-6955,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-7650,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-8345,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-9040,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-9735,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-10430,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-11125,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-11820,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-1478.4,-12515,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-350,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-1045,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-1740,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-2435,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-3130,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-3825,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-4520,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-5215,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-5910,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-6605,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-7300,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-7995,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-8690,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-9385,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-10080,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-10775,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-11470,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <-701.1,-12165,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-5,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-700,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-1395,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-2090,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-2785,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-3480,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-4175,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-4870,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-5565,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-6260,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-6955,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-7650,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-8345,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-9040,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-9735,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-10430,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-11125,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-11820,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <76.2,-12515,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-350,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-1045,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-1740,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-2435,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-3130,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-3825,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-4520,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-5215,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-5910,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-6605,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-7300,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-7995,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-8690,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-9385,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-10080,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-10775,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-11470,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <853.5,-12165,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-5,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-700,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-1395,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-2090,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-2785,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-3480,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-4175,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-4870,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-5565,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-6260,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-6955,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-7650,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-8345,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-9040,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-9735,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-10430,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-11125,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-11820,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <1630.8,-12515,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-350,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-1045,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-1740,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-2435,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-3130,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-3825,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-4520,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-5215,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-5910,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-6605,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-7300,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-7995,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-8690,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-9385,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-10080,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-10775,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-11470,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <2408.1,-12165,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-5,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-700,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-1395,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-2090,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-2785,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-3480,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-4175,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-4870,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-5565,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-6260,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-6955,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-7650,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-8345,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-9040,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-9735,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-10430,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-11125,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-11820,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3185.4,-12515,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-350,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-1045,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-1740,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-2435,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-3130,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-3825,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-4520,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-5215,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-5910,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-6605,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-7300,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-7995,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-8690,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-9385,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-10080,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-10775,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-11470,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <3962.7,-12165,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-5,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-700,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-1395,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-2090,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-2785,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-3480,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-4175,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-4870,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-5565,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-6260,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-6955,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-7650,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-8345,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-9040,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-9735,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-10430,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-11125,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-11820,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <4740,-12515,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-350,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-1045,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-1740,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-2435,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-3130,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-3825,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-4520,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-5215,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-5910,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-6605,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-7300,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-7995,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-8690,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-9385,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-10080,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-10775,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-11470,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <5517.3,-12165,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-5,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-700,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-1395,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-2090,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-2785,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-3480,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-4175,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-4870,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-5565,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-6260,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-6955,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-7650,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-8345,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-9040,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-9735,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-10430,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-11125,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-11820,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <6294.6,-12515,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-350,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-1045,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-1740,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-2435,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-3130,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-3825,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-4520,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-5215,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-5910,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-6605,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-7300,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-7995,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-8690,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-9385,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-10080,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-10775,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-11470,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7071.9,-12165,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-5,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-700,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-1395,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-2090,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-2785,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-3480,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-4175,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-4870,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-5565,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-6260,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-6955,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-7650,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-8345,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-9040,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-9735,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-10430,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-11125,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-11820,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <7849.2,-12515,40720>, <0,0,180>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-350,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-1045,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-1740,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-2435,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-3130,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-3825,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-4520,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-5215,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-5910,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-6605,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-7300,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-7995,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-8690,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-9385,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-10080,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-10775,40720>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-11470,40719.99>, <0,0,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/highrise_rectangle_top_01.rmdl", <8626.5,-12165,40720>, <0,0,180>, true, 8000, -1 )




	//Concrete Barrier
    CreateEditorProp( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3120,-4992.22,40719>, <0,0,0>, true, 8000, -1 )
	CreateEditorProp( $"mdl/desertlands/desertlands_barrier_concrete_128_01.rmdl", <3050.97,-4992.21,40718.99>, <0,0,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/barriers/concrete/concrete_barrier_01.rmdl", <3482.97,-4728.56,40719.2>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/barriers/concrete/concrete_barrier_01.rmdl", <3482.93,-4660.35,40719.1>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/barriers/concrete/concrete_barrier_01.rmdl", <3483.06,-4600.67,40719.3>, <0,0,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/barriers/concrete/concrete_barrier_fence_128.rmdl", <3482.97,-4695,40680>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/barriers/concrete/concrete_barrier_fence_128.rmdl", <3482.97,-4635,40680>, <0,0,0>, true, 8000, -1 )




    //Farmland Crates
    //CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_01.rmdl", <3499.13,-4533.92,40719.5>, <0,90,0>, true, 8000, -1 )
    //CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_02.rmdl", <3582.41,-4533.85,40719.2>, <0,-90,0>, true, 8000, -1 )

	//Cargo Containers and Farmland Crates
        //Middle 3
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_white.rmdl", <2932.24,-4945,40719>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <2932.09,-4790,40719>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_red.rmdl", <2824.96,-4868.50,40719>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_red.rmdl", <2770.96,-4868.40,40719.5>, <0,0,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/containers/pelican_case_large_drabgreen.rmdl", <2939.05,-4867.88,40719.7>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/containers/pelican_case_large_drabgreen.rmdl", <2939.05,-4867.88,40751>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/containers/pelican_case_large_drabgreen.rmdl", <2939.05,-4867.88,40782.3>, <0,0,0>, true, 8000, -1 )

        //Vehicle
    CreateEditorProp( $"mdl/vehicles_r5/land/msc_suv_partum/veh_land_msc_suv_partum_static.rmdl", <2650,-4930,40719.2>, <0,-90,0>, true, 8000, -1 )

        //Under right plate wing
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <3440,-4810,40719>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <3545,-4810,40719>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_white.rmdl", <3530.29,-4511.52,40719>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <3565,-4513.52,40718.99>, <0,180,0>, true, 8000, -1 )

        //Near front
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <3368,-5504.99,40719.8>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <3472.06,-5504.82,40719.4>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <3368.02,-5631.79,40719>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <3472.01,-5635.9,40719>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <3472.93,-5627.92,40719.6>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/cargo_container_imc_01_blue.rmdl", <3368.93,-5627.97,40719.6>, <0,90,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_01.rmdl", <3472,-5412.59,40719>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_03.rmdl", <3552,-5552.19,40719>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_01.rmdl", <3551.84,-5639.56,40719>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_01.rmdl", <3616.03,-5639.34,40719>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_03.rmdl", <3440.86,-5728.2,40719>, <0,90,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_01.rmdl", <3479.91,-5480.65,40815.2>, <0,15,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_03.rmdl", <3548.01,-5552.43,40790>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_03.rmdl", <3428.75,-5648.17,40815.4>, <0,105,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_03.rmdl", <3395.73,-5512.47,40815.2>, <0,150,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_03.rmdl", <3479.91,-5568.46,40815.1>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/colony/farmland_crate_md_80x64x72_01.rmdl", <3516.5,-5640.06,40815.1>, <0,-90,0>, true, 8000, -1 )

    //Plane Ramp
    CreateEditorProp( $"mdl/playback/playback_bridge_panel_128x064_01.rmdl", <3330,-5070,40702>, <0,-90,35>, true, 8000, -1 )
    CreateEditorProp( $"mdl/playback/playback_bridge_panel_128x064_01.rmdl", <3330,-5120,40702>, <0,-90,35>, true, 8000, -1 )

    CreateEditorProp( $"mdl/playback/playback_bridge_panel_128x064_01.rmdl", <3412,-5120,40760>, <0,-90,35>, true, 8000, -1 )
    CreateEditorProp( $"mdl/playback/playback_bridge_panel_128x064_01.rmdl", <3412,-5070,40760>, <0,-90,35>, true, 8000, -1 )

    CreateEditorProp( $"mdl/playback/playback_bridge_panel_128x064_01.rmdl", <3454,-5120,40788.4>, <0,-90,40>, true, 8000, -1 )
    CreateEditorProp( $"mdl/playback/playback_bridge_panel_128x064_01.rmdl", <3454,-5070,40788.4>, <0,-90,40>, true, 8000, -1 )

    CreateEditorProp( $"mdl/playback/playback_bridge_panel_128x064_01.rmdl", <3478,-5120,40808>, <0,-90,42>, true, 8000, -1 )
    CreateEditorProp( $"mdl/playback/playback_bridge_panel_128x064_01.rmdl", <3478,-5070,40808>, <0,-90,42>, true, 8000, -1 )

    //Plane Ramp Railings
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3388,-5072.54,40751.2>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3436.04,-5072.52,40783.1>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3457,-5072.52,40797>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3500,-5072.54,40836.5>, <-8,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3542,-5072.54,40874>, <-8,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3575,-5072.54,40903>, <-8,0,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3388,-5183,40751.2>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3436.04,-5183,40783.1>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3457,-5183,40797>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3500,-5183,40836.5>, <-8,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3542,-5183,40874>, <-8,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/railing_stairs_metal_dirty_48_01.rmdl", <3575,-5183,40903>, <-8,0,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/ola/sewer_stair_railing_01.rmdl", <3379.6,-5072.54,40743.2>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/ola/sewer_stair_railing_01.rmdl", <3437.3,-5072.54,40781.7>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/ola/sewer_stair_railing_01.rmdl", <3500,-5072.54,40824.1>, <0,-90,8>, true, 8000, -1 )
    CreateEditorProp( $"mdl/ola/sewer_stair_railing_01.rmdl", <3552,-5072.54,40870.5>, <0,-90,8>, true, 8000, -1 )

    CreateEditorProp( $"mdl/ola/sewer_stair_railing_01.rmdl", <3379.6,-5183.65,40743.2>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/ola/sewer_stair_railing_01.rmdl", <3437.3,-5183.65,40781.7>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/ola/sewer_stair_railing_01.rmdl", <3500,-5183.65,40824.1>, <0,-90,8>, true, 8000, -1 )
    CreateEditorProp( $"mdl/ola/sewer_stair_railing_01.rmdl", <3552,-5183.65,40870.5>, <0,-90,8>, true, 8000, -1 )
    

    //Sewer Staircase
    //CreateEditorProp( $"mdl/ola/sewer_staircase_01.rmdl", <3342,-5128,40729.5>, <0,180,0>, true, 8000, -1 )
    //CreateEditorProp( $"mdl/ola/sewer_staircase_quad.rmdl", <3552,-5128,40867.5>, <0,180,0>, true, 8000, -1 )

    //Plane Platform
    //CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-5896,40884>, <0,90,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-5394,40884.1>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-5384,40884>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-5128,40884>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-4872,40884>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-4616,40884>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-4360,40884>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-4104,40884>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-3848,40884>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3696,-3592,40884>, <0,90,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3760,-5394,40884.2>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3760,-5384,40883.9>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3760,-5128,40883.9>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3760,-4872,40883.9>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3760,-4616,40883.9>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3760,-4360,40883.9>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3760,-4104,40883.9>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3760,-3848,40883.9>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl", <3760,-3592,40883.9>, <0,90,0>, true, 8000, -1 )

    

    //Plane Top
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3730,-3860,40085>, <-90,0,-90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3730,-4065,40085>, <-90,0,-90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3730,-4270,40085>, <-90,0,-90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3730,-4475,40085>, <-90,0,-90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3730,-4680,40085>, <-90,0,-90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3730,-4885,40085>, <-90,0,-90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3730,-5090,40085>, <-90,0,-90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3170,-5227,40280>, <-50,0,-90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3730,-5370,40085>, <-90,0,-90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3731,-5440,40085>, <-90,0,-90>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <4393,-5370,40397>, <220,0,90>, true, 8000, -1 )
    

    //Plane Bottom
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3729.9,-3655,41820>, <90,0,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3729.9,-3860,41820>, <90,0,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3729.9,-4065,41820>, <90,0,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3729.9,-4270,41820>, <90,0,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3729.9,-4475,41820>, <90,0,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3729.9,-4680,41820>, <90,0,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3729.9,-4890,41820>, <90,0,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3729.9,-5165,41820>, <90,0,90>, true, 8000, -1 )
    //CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_mid.rmdl", <3729.9,-5370,41820>, <90,0,90>, true, 8000, -1 )

    //Plane Nose
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_bott.rmdl", <3728,-4724.41,41100>, <0,-90,-180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_elevator_01_bott.rmdl", <3728.05,-4724.4,40901>, <0,-90,0>, true, 8000, -1 )

    //Plane Cockpit Door Frame
    CreateEditorProp( $"mdl/desertlands/industrial_door_frame_128x128_01.rmdl", <3730,-5528.34,40899.6>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/industrial_door_frame_128x128_01.rmdl", <3730,-5520,40899.6>, <0,270,0>, true, 8000, -1 )

    //Plane Cockpit Walls
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3810,-5528.5,40899.5>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3855,-5528.45,40899.5>, <0,90,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3810,-5660,40899.5>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3855,-5660.1,40899.8>, <0,-90,0>, true, 8000, -1 )


    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3650,-5520,40899.5>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3650,-5528.5,40899.5>, <0,90,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3650,-5520,40899.5>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3605,-5520,40899.5>, <0,-90,0>, true, 8000, -1 )
        //Top

    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3743,-5528.5,41059>, <0,90,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3573,-5528.5,41059>, <0,90,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3657,-5528,41059>, <0,90,90>, true, 8000, -1 )
    
    
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3717,-5528,41059>, <0,-90,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3887,-5528,41059>, <0,-90,90>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_64x144_01.rmdl", <3800,-5528.5,41059>, <0,-90,90>, true, 8000, -1 )

    //Plane Wing
        //Right Wing
    CreateEditorProp( $"mdl/desertlands/construction_bldg_platform_04_corner.rmdl", <3712,-4860,40890>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_platform_04_corner.rmdl", <3570,-4718,40889>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_platform_04_corner.rmdl", <3428,-4576,40888>, <0,-90,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/desertlands_city_slanted_building_01_wall_wedge.rmdl", <2800.66,-4050,40870>, <0,-104,270>, true, 8000, -1 )
    
        //Left Wing
    CreateEditorProp( $"mdl/desertlands/construction_bldg_platform_04_corner.rmdl", <3712,-4880,40845>, <0,-90,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_platform_04_corner.rmdl", <3854,-4738,40844>, <0,-90,180>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/construction_bldg_platform_04_corner.rmdl", <3996,-4596,40843>, <0,-90,180>, true, 8000, -1 )
    
    CreateEditorProp( $"mdl/desertlands/desertlands_city_slanted_building_01_wall_wedge.rmdl", <4623.66,-4060,40870>, <0,-74,90>, true, 8000, -1 )



    

    //Plane Cockpit Interior
    
        //global_access_panel_button_console_w_stand
    //CreateEditorProp( $"mdl/props/global_access_panel_button/global_access_panel_button_console_w_stand.rmdl", <3768,-5643,40899.2>, <0,180,0>, true, 8000, -1 )
    //CreateEditorProp( $"mdl/props/global_access_panel_button/global_access_panel_button_console_w_stand.rmdl", <3688,-5643,40899.3>, <0,180,0>, true, 8000, -1 )
        //Seats
    CreateEditorProp( $"mdl/desertlands/mobile_vehicle_01_seat_01.rmdl", <3791,-5595,40900>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/mobile_vehicle_01_seat_01.rmdl", <3663,-5595,40900>, <0,-90,0>, true, 8000, -1 )
        //Tech Panelsquares
    CreateEditorProp( $"mdl/IMC_base/imc_tech_panelsquare_48_05.rmdl", <3826.64,-5693,40899.2>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/imc_tech_panelsquare_48_05.rmdl", <3788.61,-5693.2,40899>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/imc_tech_panelsquare_48_05.rmdl", <3740.61,-5693,40899.2>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/imc_tech_panelsquare_48_05.rmdl", <3714.61,-5693.2,40899>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/imc_tech_panelsquare_48_05.rmdl", <3666.64,-5693,40899.2>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/imc_tech_panelsquare_48_05.rmdl", <3628.61,-5693.2,40899>, <0,90,0>, true, 8000, -1 )
        //Monitor Command Small
    CreateEditorProp( $"mdl/IMC_base/monitor_command_small_imc_01.rmdl", <3835,-5627.65,40950>, <0,-135,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/monitor_command_small_imc_01.rmdl", <3620,-5627.65,40950>, <0,-45,180>, true, 8000, -1 )
        //imc_tech_tallpanel_48_02
    CreateEditorProp( $"mdl/IMC_base/imc_tech_tallpanel_48_02.rmdl", <3871.5,-5553,40899.3>, <0,180,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/imc_tech_tallpanel_48_02.rmdl", <3872,-5585,40899>, <0,180,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/IMC_base/imc_tech_tallpanel_48_02.rmdl", <3583.5,-5553,40899.3>, <0,0,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/IMC_base/imc_tech_tallpanel_48_02.rmdl", <3584,-5585,40899>, <0,0,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/mobile_vehicle_01_console_01.rmdl", <3727.53,-5610,40900>, <0,-90,0>, true, 8000, -1 )
    

    //Plane Bathroom
    CreateEditorProp( $"mdl/colony/farmland_bathroom_01.rmdl", <3591.82,-5518,40899.8>, <0,0,0>, true, 8000, -1 )

    //Building with stairs, garage and tank
        //North wall
    CreateEditorProp( $"mdl/desertlands/desertlands_city_slanted_building_01_wall_64.rmdl", <2745,-5350,40719.5>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/desertlands_city_slanted_building_01_wall_64.rmdl", <2364,-5350,40719.5>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/desertlands/desertlands_city_slanted_building_01_wall_64.rmdl", <2487,-5349.97,40719.5>, <0,90,0>, true, 8000, -1 )
        //East wall
    CreateEditorProp( $"mdl/desertlands/desertlands_city_slanted_building_01_wall_64.rmdl", <2770,-5375,40719.5>, <0,0,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/fence_large_concrete_metal_dirty_192_01.rmdl", <4276.16,-6152.96,40719.8>, <0,90,0>, true, 8000, -1 )
        //Stairs
    CreateEditorProp( $"mdl/ola/sewer_staircase_short_quad.rmdl", <2839.89,-5356.82,40751.4>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/ola/sewer_staircase_short_quad.rmdl", <2839.89,-5404.83,40783.4>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/ola/sewer_staircase_short_quad.rmdl", <2839.89,-5452.84,40815.4>, <0,90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/ola/sewer_staircase_short_double.rmdl", <2839.89,-5476.84,40831.4>, <0,90,0>, true, 8000, -1 )
        //Stairs platform
    CreateEditorProp( $"mdl/colony/ventilation_unit_01_black.rmdl", <2839.97,-5525,40816>, <0,0,0>, true, 8000, -1 )
    
        //Garage Door
    CreateEditorProp( $"mdl/desertlands/industrial_metal_frame_wall_256x144_04.rmdl", <2560,-5311,40719.4>, <0,90,0>, true, 8000, -1 )
        //Barrier near garage door
    CreateEditorProp( $"mdl/barriers/concrete/concrete_barrier_01.rmdl", <2687,-5266,40719.4>, <0,7,0>, true, 8000, -1 )
        //Fuse box
    CreateEditorProp( $"mdl/electricalboxes/fusebox_rusty.rmdl", <2763.88,-5308.97,40787.8>, <0,-90,0>, true, 8000, -1 )
        
    


    //Airport building right
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <2291.46,-5205,40520>, <0,-90,0>, true, 8000, -1 )
    CreateEditorProp( $"mdl/thunderdome/thunderdome_cage_wall_256x256_01.rmdl", <2283,-5205,40520>, <0,-90,0>, true, 8000, -1 )
    






    //Placers

    CreateEditorProp( $"mdl/desertlands/desertlands_train_track_sign_01.rmdl", <2559.73,-6144.94,40767.8>, <0,0,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/lightpole_desertlands_city_01.rmdl", <2624.73,-6144.67,40767.9>, <0,90,0>, true, 8000, -1 )

    CreateEditorProp( $"mdl/desertlands/fence_large_concrete_metal_dirty_192_01.rmdl", <4276.16,-6152.96,40719.8>, <0,90,0>, true, 8000, -1 )





    


    




    


    


	


}



#endif
