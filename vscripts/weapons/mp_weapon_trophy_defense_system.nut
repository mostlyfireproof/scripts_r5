//=========================================================
//	mp_weapon_trophy_defense_system.nut
//=========================================================

untyped

global function MpWeaponTrophy_Init
global function OnWeaponAttemptOffhandSwitch_weapon_trophy_defense_system

global function OnWeaponActivate_weapon_trophy_defense_system
global function OnWeaponDeactivate_weapon_trophy_defense_system
global function OnWeaponPrimaryAttack_weapon_trophy_defense_system

#if CLIENT
global function SCB_WattsonRechargeHint
#endif

// FX
const asset TROPHY_START_FX = $"P_wpn_trophy_loop_st"
const asset TROPHY_ELECTRICITY_FX = $"P_wpn_trophy_loop_1"
const asset TROPHY_INTERCEPT_PROJECTILE_SMALL_FX = $"P_wpn_trophy_imp_sm"//
const asset TROPHY_INTERCEPT_PROJECTILE_LARGE_FX = $"P_wpn_trophy_imp_lg"
const asset TROPHY_INTERCEPT_PROJECTILE_CLOSE_FX = $"P_wpn_trophy_imp_lite"
const asset TROPHY_DAMAGE_SPARK_FX = $"P_trophy_sys_dmg"
const asset TROPHY_DESTROY_FX = $"P_trophy_sys_exp"
const asset TROPHY_COIL_ON_FX = $"P_wpn_trophy_coil_spin"
const asset TROPHY_PLAYER_TACTICAL_CHARGE_FX = $"P_wat_menu_coil_loop"
const asset TROPHY_PLAYER_SHIELD_CHARGE_FX = $"P_armor_3P_loop_CP"
const asset TROPHY_RANGE_RADIUS_REMINDER_FX = $"P_wpn_trophy_ar_ring_flash"

#if SERVER || CLIENT
const asset TROPHY_PLACEMENT_RADIUS_FX 		= $"P_wpn_trophy_ar_ring"
#endif // SERVER || CLIENT

// FX Table
global const string TROPHY_SYSTEM_NAME = "trophy_system"
const TROPHY_TARGET_EXPLOSION_IMPACT_TABLE = "exp_medium"

// Model
const asset TROPHY_MODEL = $"mdl/props/wattson_trophy_system/wattson_trophy_system.rmdl"

// Sound
const string TROPHY_PLACEMENT_ACTIVATE_SOUND 	= "wattson_tactical_a"
const string TROPHY_PLACEMENT_DEACTIVATE_SOUND 	= "wattson_tactical_b"

const string TROPHY_EXPAND_SOUND		= "Wattson_Ultimate_E"
const string TROPHY_EXPAND_ENEMY_SOUND	= "Wattson_Ultimate_E_Enemy"
const string TROPHY_ELECTRIC_IDLE_SOUND = "Wattson_Ultimate_F"
const string TROPHY_TACTICAL_CHARGE_SOUND = "Wattson_Ultimate_G"

const string TROPHY_INTERCEPT_BEAM_SOUND 	= "Wattson_Ultimate_H"
const string TROPHY_INTERCEPT_LARGE			= "Wattson_Ultimate_I"
const string TROPHY_INTERCEPT_SMALL			= "Wattson_Ultimate_J"
const string TROPHY_DESTROY_SOUND			= "Wattson_Ultimate_K"
const string TROPHY_SHIELD_REPAIR_START     = "Wattson_Ultimate_L"
const string TROPHY_SHIELD_REPAIR_END       = "Wattson_Ultimate_N"

// Placement
const float TROPHY_PLACEMENT_RANGE_MAX = 94
const float TROPHY_PLACEMENT_RANGE_MIN = 64
const float TROPHY_PLACEMENT_SPACING_MIN = 64
const float TROPHY_PLACEMENT_SPACING_MIN_SQR = TROPHY_PLACEMENT_SPACING_MIN * TROPHY_PLACEMENT_SPACING_MIN
const vector TROPHY_BOUND_MINS = <-32,-32,0>
const vector TROPHY_BOUND_MAXS = <32,32,72>
const vector TROPHY_PLACEMENT_TRACE_OFFSET = <0,0,94>
const float TROPHY_PLACEMENT_MAX_GROUND_DIST = 12.0

// Intersection
const vector TROPHY_INTERSECTION_BOUND_MINS = <-16,-16,0>
const vector TROPHY_INTERSECTION_BOUND_MAXS = <16,16,32>

// 
const float TROPHY_ANGLE_LIMIT = 0.74
const float TROPHY_DEPLOY_DELAY = 1.0

// Damage
const int TROPHY_HEALTH_AMOUNT = 150
const float TROPHY_DAMAGE_FX_INTERVAL = 0.25

// Projectile
const float TROPHY_INTERCEPT_PROJECTILE_RANGE = 512.0
const float TROPHY_INTERCEPT_PROJECTILE_RANGE_MIN = 256.0 //
const float TROPHY_INTERCEPT_PROJECTILE_RANGE_MIN_SQR = TROPHY_INTERCEPT_PROJECTILE_RANGE_MIN * TROPHY_INTERCEPT_PROJECTILE_RANGE_MIN

// 
const float TROPHY_ARC_SCREEN_EFFECT_RADIUS = TROPHY_INTERCEPT_PROJECTILE_RANGE
const float WATTSON_TROPHY_CHARGE_POPUP_COOLDOWN = 3.5

// Redeploy
const float TROPHY_SHIELD_REPAIR_INTERVAL = 0.5
const int 	TROPHY_SHIELD_REPAIR_AMOUNT	= 1
const float TROPHY_LOS_CHARGE_TIMEOUT = 1.0
const asset TACTICAL_CHARGE_FX = $"P_player_boost_screen"//

// Max
const int TROPHY_MAX_COUNT = 1

// Trigger
const float TROPHY_REMINDER_TRIGGER_RADIUS = 300.0
const float TROPHY_REMINDER_TRIGGER_DBOUNCE = 30.0

// Animations, thanks @r-ex!
const string CLOSE = "prop_trophy_close"
const string EXPAND = "prop_trophy_expand"				// for placing
const string IDLE_CLOSED = "prop_trophy_idle_closed"
const string IDLE_OPEN = "prop_trophy_idle_open"		// actually makes it spin like in retail
const string SPIN = "prop_trophy_idle_open_spin"		// slow spin

// Debug
const bool TROPHY_DEBUG_DRAW = false
const bool TROPHY_DEBUG_DRAW_PLACEMENT = false
const bool TROPHY_DEBUG_DRAW_INTERSECTION = false


#if CLIENT
const float TROPHY_ICON_HEIGHT = 68.0
#endif //

struct TrophyPlacementInfo
{
	vector origin
	vector angles
	entity parentTo
	bool success = false
}

#if SERVER

// Throwing GC stuff here, adapted from sh_loot_creeps.gnut
global function TrophyDefenseGarbageCollect

#endif // SERVER

struct SignalStruct
{
	entity trigger
	entity player
}

struct
{
	#if SERVER
	array<entity>	trophyDefenseSystems
	int				numActiveTrophyDefenseSystems
	float			lastTimeTrophyDefenseSystemsGarbageCollected
	array<SignalStruct> signalStructArray
	#else
	int tacticalChargeFXHandle
	#endif
} file


function MpWeaponTrophy_Init()
{
	PrecacheParticleSystem( TROPHY_START_FX )
	PrecacheParticleSystem( TROPHY_ELECTRICITY_FX )
	PrecacheParticleSystem( TROPHY_INTERCEPT_PROJECTILE_SMALL_FX )
	PrecacheParticleSystem( TROPHY_INTERCEPT_PROJECTILE_LARGE_FX )
	PrecacheParticleSystem( TROPHY_INTERCEPT_PROJECTILE_CLOSE_FX )
	PrecacheParticleSystem( TROPHY_DAMAGE_SPARK_FX )
	PrecacheParticleSystem( TROPHY_DESTROY_FX )
	PrecacheParticleSystem( TROPHY_COIL_ON_FX )
	PrecacheParticleSystem( TROPHY_PLAYER_TACTICAL_CHARGE_FX )
	PrecacheParticleSystem( TROPHY_PLAYER_SHIELD_CHARGE_FX )
	PrecacheParticleSystem( TROPHY_RANGE_RADIUS_REMINDER_FX )

	PrecacheModel( TROPHY_MODEL )

	#if SERVER
		// RegisterSignal( OnTrophyShieldAreaEnter )
		// RegisterSignal( OnTrophyShieldAreaLeave )

		// More GC stuff
		file.lastTimeTrophyDefenseSystemsGarbageCollected = Time()

	#endif //

	#if CLIENT
		PrecacheParticleSystem( TACTICAL_CHARGE_FX )
		PrecacheParticleSystem( TROPHY_PLACEMENT_RADIUS_FX )
		StatusEffect_RegisterEnabledCallback( eStatusEffect.placing_trophy_system, Trophy_OnBeginPlacement)
		StatusEffect_RegisterDisabledCallback( eStatusEffect.placing_trophy_system, Trophy_OnEndPlacement )
		AddCreateCallback( "prop_script", Trophy_OnPropScriptCreated )

		RegisterSignal( "Trophy_StopPlacementProxy" )
		RegisterSignal( "EndTacticalChargeRepair" )
		RegisterSignal( "EndTacticalShieldRepair" )
		RegisterSignal( "UpdateShieldRepair" )

		StatusEffect_RegisterEnabledCallback( eStatusEffect.trophy_tactical_charge, TacticalChargeVisualsEnabled)
		StatusEffect_RegisterDisabledCallback( eStatusEffect.trophy_tactical_charge, TacticalChargeVisualsDisabled )

		StatusEffect_RegisterEnabledCallback( eStatusEffect.trophy_shield_repair, ShieldRepairVisualsEnabled )
		StatusEffect_RegisterDisabledCallback( eStatusEffect.trophy_shield_repair, ShieldRepairVisualsDisabled )

		AddCallback_OnWeaponStatusUpdate( Trophy_OnWeaponStatusUpdate )
	#endif // CLIENT

	thread MpWeaponTrophyLate_Init()
}

void function MpWeaponTrophyLate_Init()
{
	WaitEndFrame()

	#if CLIENT
		AddCallback_OnEquipSlotTrackingIntChanged( "armor", ArmorChanged )
	#endif // CLIENT
}

void function OnWeaponActivate_weapon_trophy_defense_system( entity weapon )
{
	entity ownerPlayer = weapon.GetWeaponOwner()
	Assert( ownerPlayer.IsPlayer() )
	#if CLIENT
		if ( !InPrediction() ) //
			return
	#endif

	int statusEffect = eStatusEffect.placing_trophy_system
	StatusEffect_AddEndless( ownerPlayer, statusEffect, 1.0 )
}

void function OnWeaponDeactivate_weapon_trophy_defense_system( entity weapon )
{
	entity ownerPlayer = weapon.GetWeaponOwner()
	Assert( ownerPlayer.IsPlayer() )
	#if CLIENT
		if ( !InPrediction() ) //
			return
	#endif

	StatusEffect_StopAllOfType( ownerPlayer, eStatusEffect.placing_trophy_system )
}

bool function OnWeaponAttemptOffhandSwitch_weapon_trophy_defense_system( entity weapon )
{
	int ammoReq = weapon.GetAmmoPerShot()
	int currAmmo = weapon.GetWeaponPrimaryClipCount()
	if ( currAmmo < ammoReq )
		return false

	entity player = weapon.GetWeaponOwner()
	if ( player.IsPhaseShifted() )
		return false

	if ( player.IsZiplining() )
		return false

	return true
}

var function OnWeaponPrimaryAttack_weapon_trophy_defense_system( entity weapon, WeaponPrimaryAttackParams attackParams )
{
	entity ownerPlayer = weapon.GetWeaponOwner()
	Assert( ownerPlayer.IsPlayer() )

	asset model = TROPHY_MODEL

	entity proxy                      = Trophy_CreateTrapPlacementProxy( model )
	TrophyPlacementInfo placementInfo = Trophy_GetPlacementInfo( ownerPlayer, proxy )
	proxy.Destroy()

	if ( !placementInfo.success )
		return 0

	#if SERVER
		// TODO: implement all the stuff here
		// TODO: limit placement to TROPHY_MAX_COUNT, use dirty bomb code?
		// apparently the collision is a separate model according to Sal

		thread WeaponMakesDefenseSystem(weapon, model, placementInfo)
		PlayBattleChatterLineToSpeakerAndTeam( ownerPlayer, "bc_super" )
	#endif
	StatusEffect_StopAllOfType( ownerPlayer, eStatusEffect.placing_trophy_system )
	PlayerUsedOffhand( ownerPlayer, weapon, true, null, {pos = placementInfo.origin} )

	int ammoReq = weapon.GetAmmoPerShot()
	return ammoReq
}

/*






*/

TrophyPlacementInfo function Trophy_GetPlacementInfo( entity player, entity proxy )
{
	vector eyePos  = player.EyePosition()
	vector viewVec = player.GetViewVector()
	vector angles  = < 0, VectorToAngles( viewVec ).y, 0 >

	float maxRange = TROPHY_PLACEMENT_RANGE_MAX

	TraceResults viewTraceResults = TraceLine( eyePos, eyePos + player.GetViewVector() * ( TROPHY_PLACEMENT_RANGE_MAX * 2), [player, proxy], TRACE_MASK_SOLID, TRACE_COLLISION_GROUP_NONE )
	if ( viewTraceResults.fraction < 1.0 )
	{
		float slope = fabs( viewTraceResults.surfaceNormal.x ) + fabs( viewTraceResults.surfaceNormal.y )
		if ( slope < TROPHY_ANGLE_LIMIT )
			maxRange = min( Distance( eyePos, viewTraceResults.endPos ), TROPHY_PLACEMENT_RANGE_MAX )
	}

	vector idealPos = player.GetOrigin() + ( AnglesToForward( angles ) * TROPHY_PLACEMENT_RANGE_MAX )
	TraceResults fwdResults = TraceHull( eyePos + viewVec * min( TROPHY_PLACEMENT_RANGE_MIN, maxRange ), eyePos + viewVec * maxRange, TROPHY_BOUND_MINS, TROPHY_BOUND_MAXS, [player, proxy], TRACE_MASK_SOLID, TRACE_COLLISION_GROUP_NONE )
	TraceResults downResults = TraceHull( fwdResults.endPos, fwdResults.endPos - TROPHY_PLACEMENT_TRACE_OFFSET, TROPHY_BOUND_MINS, TROPHY_BOUND_MAXS, [player, proxy], TRACE_MASK_SOLID, TRACE_COLLISION_GROUP_NONE )

	if ( TROPHY_DEBUG_DRAW_PLACEMENT )
	{
		DebugDrawBox( fwdResults.endPos, TROPHY_BOUND_MINS, TROPHY_BOUND_MAXS, 0, 255, 0, 1, 1.0 ) //
		DebugDrawBox( downResults.endPos, TROPHY_BOUND_MINS, TROPHY_BOUND_MAXS, 0, 0, 255, 1, 1.0 ) //
		DebugDrawLine( eyePos + viewVec * min( TROPHY_PLACEMENT_RANGE_MIN, maxRange ), fwdResults.endPos, 0, 255, 0, true, 1.0 ) //
		DebugDrawLine( fwdResults.endPos, eyePos + viewVec * maxRange, 255, 0, 0, true, 1.0 ) //
		DebugDrawLine( fwdResults.endPos, downResults.endPos, 0, 0, 255, true, 1.0 ) //
		DebugDrawLine( player.GetOrigin(), player.GetOrigin() + ( AnglesToForward( angles ) * TROPHY_PLACEMENT_RANGE_MAX ), 0, 255, 0, true, 1.0 ) //
		DebugDrawLine( eyePos + <0,0,8>, eyePos + <0,0,8> + ( viewVec * TROPHY_PLACEMENT_RANGE_MAX ), 0, 255, 0, true, 1.0 ) //
	}

	//
	bool isScriptedPlaceable = false
	if ( IsValid( downResults.hitEnt ) )
	{
		var hitEntClassname = downResults.hitEnt.GetNetworkedClassName()

		if ( hitEntClassname == "func_brush" || hitEntClassname == "script_mover" )
		{
			isScriptedPlaceable = true
		}
		else if ( hitEntClassname == "prop_script" )
		{
			if ( downResults.hitEnt.GetScriptPropFlags() == PROP_IS_VALID_FOR_TURRET_PLACEMENT )
				isScriptedPlaceable = true
		}
	}

	bool success = !downResults.startSolid && downResults.fraction < 1.0 && ( downResults.hitEnt.IsWorld() || isScriptedPlaceable )

	entity parentTo
	if ( IsValid( downResults.hitEnt ) && ( downResults.hitEnt.GetNetworkedClassName() == "func_brush" || downResults.hitEnt.GetNetworkedClassName() == "script_mover" ) )
	{
		parentTo = downResults.hitEnt
	}

	if ( downResults.startSolid && downResults.fraction < 1.0 && ( downResults.hitEnt.IsWorld() || isScriptedPlaceable ) )
	{
		TraceResults upResults = TraceHull( downResults.endPos, downResults.endPos, TROPHY_BOUND_MINS, TROPHY_BOUND_MAXS, [player, proxy], TRACE_MASK_SOLID, TRACE_COLLISION_GROUP_NONE )
		if ( !upResults.startSolid )
		{
			success = true
		}
		else
		{
			//
		}
	}

	vector surfaceAngles = angles

	//
	//
	if ( success && !PlayerCanSeePos( player, downResults.endPos, true, 90 ) )
	{
		surfaceAngles = angles
		success = false
		//
	}

	//
	if ( success && viewTraceResults.hitEnt != null && ( !viewTraceResults.hitEnt.IsWorld() && !isScriptedPlaceable ) )
	{
		surfaceAngles = angles
		success = false
	//
	}

	//
	if ( success && downResults.fraction < 1.0 )
	{
		surfaceAngles 	= AnglesOnSurface( downResults.surfaceNormal, AnglesToForward( angles ) )
		vector newUpDir = AnglesToUp( surfaceAngles )
		vector oldUpDir = AnglesToUp( angles )

		//
		proxy.SetOrigin( downResults.endPos )
		proxy.SetAngles( surfaceAngles )

		vector right = proxy.GetRightVector()
		vector forward = proxy.GetForwardVector()

		float length = Length( TROPHY_BOUND_MINS )

		array< vector > groundTestOffsets = [
			Normalize( right * 2 + forward ) * length,
			Normalize( -right * 2 + forward ) * length,
			Normalize( right * 2 + -forward ) * length,
			Normalize( -right * 2 + -forward ) * length
		]

		if ( TROPHY_DEBUG_DRAW_PLACEMENT )
		{
			DebugDrawLine( proxy.GetOrigin(), proxy.GetOrigin() + ( right * 64 ), 0, 255, 0, true, 1.0 ) //
			DebugDrawLine( proxy.GetOrigin(), proxy.GetOrigin() + ( forward * 64 ), 0, 0, 255, true, 1.0 ) //
		}

		//
		foreach ( vector testOffset in groundTestOffsets )
		{
			vector testPos = proxy.GetOrigin() + testOffset
			TraceResults traceResult = TraceLine( testPos + ( proxy.GetUpVector() * TROPHY_PLACEMENT_MAX_GROUND_DIST ), testPos + ( proxy.GetUpVector() * -TROPHY_PLACEMENT_MAX_GROUND_DIST ), [player, proxy], TRACE_MASK_SOLID, TRACE_COLLISION_GROUP_NONE )

			if ( TROPHY_DEBUG_DRAW_PLACEMENT )
				DebugDrawLine( testPos + ( proxy.GetUpVector() * TROPHY_PLACEMENT_MAX_GROUND_DIST ), traceResult.endPos, 255, 0, 0, true, 1.0 ) //

			if ( traceResult.fraction == 1.0 )
			{
				surfaceAngles = angles
				success = false
				//
				break
			}
		}

		//
		if ( success && DotProduct( newUpDir, oldUpDir ) < TROPHY_ANGLE_LIMIT )
		{
			//
			success = false
			//
		}
	}

	TrophyPlacementInfo placementInfo
	placementInfo.success = success
	placementInfo.origin = downResults.endPos //
	placementInfo.angles = surfaceAngles
	placementInfo.parentTo = parentTo

	return placementInfo
}

entity function Trophy_CreateTrapPlacementProxy( asset modelName )
{
	#if SERVER
		entity proxy = CreatePropDynamic( modelName, <0,0,0>, <0,0,0> )
	#else
		entity proxy = CreateClientSidePropDynamic( <0,0,0>, <0,0,0>, modelName )
	#endif
	proxy.EnableRenderAlways()
	proxy.kv.rendermode = 3
	proxy.kv.renderamt = 1
	proxy.Anim_PlayOnly( IDLE_CLOSED )
	proxy.Hide()

	return proxy
}

#if CLIENT
void function Trophy_OnBeginPlacement( entity player, int statusEffect, bool actuallyChanged )
{
	if ( player != GetLocalViewPlayer() )
		return

	EmitSoundOnEntity( player, TROPHY_PLACEMENT_ACTIVATE_SOUND )

	asset model = TROPHY_MODEL

	thread Trophy_PlacementProxy( player, model )
}

void function Trophy_OnEndPlacement( entity player, int statusEffect, bool actuallyChanged )
{
	if ( player != GetLocalViewPlayer() )
		return

	EmitSoundOnEntity( player, TROPHY_PLACEMENT_DEACTIVATE_SOUND )

	player.Signal( "Trophy_StopPlacementProxy" )
}

void function Trophy_PlacementProxy( entity player, asset model )
{
	player.EndSignal( "Trophy_StopPlacementProxy" )

	entity proxy = Trophy_CreateTrapPlacementProxy( model )
	proxy.EnableRenderAlways()
	proxy.Show()
	DeployableModelHighlight( proxy )

	int fxHandle = StartParticleEffectOnEntity( proxy, GetParticleSystemIndex( TROPHY_PLACEMENT_RADIUS_FX ), FX_PATTACH_POINT_FOLLOW, proxy.LookupAttachment( "REF" ) )

	var placementRui        = CreateCockpitPostFXRui( $"ui/trophy_placement.rpak", RuiCalculateDistanceSortKey( player.EyePosition(), proxy.GetOrigin() ) )

	int placementAttachment = proxy.LookupAttachment( "REF" )
	RuiTrackFloat3( placementRui, "trophyPos", proxy, RUI_TRACK_POINT_FOLLOW, placementAttachment )

	OnThreadEnd(
		function() : ( proxy, fxHandle, placementRui )
		{

			RuiDestroy( placementRui )

			if ( EffectDoesExist( fxHandle ) )
				EffectStop( fxHandle, true, false )

			if ( IsValid( proxy ) )
				proxy.Destroy()

		}
	)

	while ( true )
	{
		proxy.ClearParent()

		TrophyPlacementInfo placementInfo = Trophy_GetPlacementInfo( player, proxy )

		RuiSetBool( placementRui, "success", placementInfo.success )

		if ( !placementInfo.success )
		{
			DeployableModelInvalidHighlight( proxy )
		}
		else if ( placementInfo.success )
		{
			DeployableModelHighlight( proxy )
		}

		proxy.SetOrigin( placementInfo.origin )
		proxy.SetAngles( placementInfo.angles )

		if ( IsValid( placementInfo.parentTo ) )
			proxy.SetParent( placementInfo.parentTo )

		//

		WaitFrame()
	}
}

void function Trophy_UpdateRadiusVisibility( int fxHandle, bool success )
{
	if ( success )
	{
		EffectWake( fxHandle )
	}
	else
	{
		EffectSleep( fxHandle )
	}
}

void function SCB_WattsonRechargeHint()
{
	if ( !IsAlive( GetLocalClientPlayer() ) )
		return

	CreateTransientCockpitRui( $"ui/wattson_ult_charge_tactical.rpak", HUD_Z_BASE )
	//
}

#endif //

/*
███████╗██╗██╗  ██╗    ████████╗██╗  ██╗██╗███████╗       ███████╗███████╗███████╗     ██████╗ ██╗████████╗    ██████╗ ██╗███████╗███████╗
██╔════╝██║╚██╗██╔╝    ╚══██╔══╝██║  ██║██║██╔════╝       ██╔════╝██╔════╝██╔════╝    ██╔════╝ ██║╚══██╔══╝    ██╔══██╗██║██╔════╝██╔════╝
█████╗  ██║ ╚███╔╝        ██║   ███████║██║███████╗       ███████╗█████╗  █████╗      ██║  ███╗██║   ██║       ██║  ██║██║█████╗  █████╗
██╔══╝  ██║ ██╔██╗        ██║   ██╔══██║██║╚════██║       ╚════██║██╔══╝  ██╔══╝      ██║   ██║██║   ██║       ██║  ██║██║██╔══╝  ██╔══╝
██║     ██║██╔╝ ██╗       ██║   ██║  ██║██║███████║██╗    ███████║███████╗███████╗    ╚██████╔╝██║   ██║       ██████╔╝██║██║     ██║  ██╗
╚═╝     ╚═╝╚═╝  ╚═╝       ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝╚═╝    ╚══════╝╚══════╝╚══════╝     ╚═════╝ ╚═╝   ╚═╝       ╚═════╝ ╚═╝╚═╝     ╚═╝  ╚═╝
*/

#if SERVER
/*
// TODO: function or something
 If this works, it will actually place Wattson's ult.
 Places to look:
  *** sh_loot_creeps.gnut ***
  *** _jump_pad.gnut ***
  * MDLSpawner_SpawnModel
  * CreateCarePackageAirdrop in sh_care_package
  * zipline
  * gas trap, gibby bubble
*/
void function WeaponMakesDefenseSystem( entity weapon, asset model, TrophyPlacementInfo placementInfo  ) {
	printf("[pylon] Placing the pylon!")

	entity owner = weapon.GetOwner()
	owner.EndSignal( "OnDestroy" )

	// realms cause it to crash on loading the map
	//	trophy.RemoveFromAllRealms()
	//	trophy.AddToOtherEntitysRealms( weapon )

	// sets up the pylon and its information
	entity pylon = CreatePropDynamic(model, placementInfo.origin, placementInfo.angles, 6)

	pylon.SetMaxHealth( TROPHY_HEALTH_AMOUNT )
	pylon.SetHealth( TROPHY_HEALTH_AMOUNT )
	pylon.SetTakeDamageType( DAMAGE_EVENTS_ONLY )
	pylon.SetDamageNotifications( true )
	pylon.SetCanBeMeleed( true )

	pylon.EndSignal( "OnDestroy" )

	// can be detected by sonar
	pylon.Highlight_Enable()
	AddSonarDetectionForPropScript( pylon )

	TrackingVision_CreatePOI( eTrackingVisionNetworkedPOITypes.PLAYER_ABILITY_TROPHY_SYSTEM, owner, pylon.GetOrigin(), owner.GetTeam(), owner )


	TrophyDeathSetup( pylon )
	
	thread Trophy_Anims( pylon )
	waitthread Trophy_CreateTriggerArea( owner, pylon )

}


// spins and makes particles
void function Trophy_Anims( entity pylon ) {
	// TODO: figure out what these signals mean
	EndSignal( pylon, "OnDestroy" )
	// entity owner = pylon.GetOwner()
	// EndSignal( owner, "OnDestroy" )

	// TODO: add particles
	EmitSoundOnEntity(pylon, TROPHY_EXPAND_SOUND)
	waitthread PlayAnim( pylon, EXPAND )
	StartParticleEffectOnEntity(pylon, GetParticleSystemIndex(TROPHY_RANGE_RADIUS_REMINDER_FX), FX_PATTACH_ABSORIGIN_FOLLOW, 0)
	thread PlayAnim( pylon, IDLE_OPEN )
}

// Creates the active area 
// based on the code i'm copying (deployable_medic.nut), this is team agnostic
// Intercepts projectiles, charges shields, and plays the sounds
void function Trophy_CreateTriggerArea( entity owner, entity pylon ) {
	printl("[pylon] Trigger area created")
	Assert ( IsNewThread(), "Must be threaded" )
	pylon.EndSignal( "OnDestroy" )

	vector origin = pylon.GetOrigin()

	// Creates a trigger for shields
	entity trigger = CreateEntity( "trigger_cylinder" )
	trigger.SetOwner( pylon )
	trigger.SetRadius( TROPHY_REMINDER_TRIGGER_RADIUS )
	trigger.SetAboveHeight( TROPHY_REMINDER_TRIGGER_RADIUS ) // not right
	trigger.SetBelowHeight( 48 )
	trigger.SetOrigin( origin )
	trigger.SetPhaseShiftCanTouch( false )
	//	trigger.kv.triggerFilterPhaseShift = "nonphaseshift"
	//	trigger.kv.triggerFilterNonCharacter = "0"
	DispatchSpawn( trigger )

	trigger.RemoveFromAllRealms()
	trigger.AddToOtherEntitysRealms( pylon )

	trigger.SetEnterCallback( OnTrophyShieldAreaEnter )
	trigger.SetLeaveCallback( OnTrophyShieldAreaLeave )

	trigger.SetOrigin( origin )


	// seems overcomplicated
	OnThreadEnd(
		function() : ( trigger )
		{
			if ( IsValid( trigger ) )
				trigger.Destroy()
		}
	)

	waitthread Trophy_ShieldUpdate( trigger, pylon )
	// TODO: create a trigger for grenades
}

void function OnTrophyShieldAreaEnter( entity trigger, entity ent )
{
	printl("[pylon] entered")
	// this could be removed once the trigger no longer gets triggered by ents in different realms. bug R5DEV-46753
	if ( !trigger.DoesShareRealms( ent ) )
		return

	if ( ent.IsPlayer() )
	{
		printt( "PLAYER " + ent + " STARTED TOUCHING TRIGGER " + trigger )
		thread Trophy_PlayerShieldUpdate( trigger, ent )
	}
	else if ( IsSurvivalTraining() && ent.GetScriptName() == "survival_training_target_dummy" ) // need to check share realm?
	{
		thread Trophy_PlayerShieldUpdate( trigger, ent )
	}
}

void function OnTrophyShieldAreaLeave( entity trigger, entity ent )
{
	printl("[pylon] leaving")
	// SignalSignalStruct( trigger, ent, "EndTacticalShieldRepair" )
}

// CreateSignalStruct, SignalSignalStruct, and DestroySignalStruct are from
// mp_weapon_deployable_medic.nut
SignalStruct function CreateSignalStruct( entity trigger, entity player )
{
	SignalStruct singalStruct
	singalStruct.player = player
	singalStruct.trigger = trigger
	file.signalStructArray.append( singalStruct )

	return singalStruct
}

void function SignalSignalStruct( entity trigger, entity player, string signal )
{
	foreach( signalStruct in file.signalStructArray )
	{
		if ( signalStruct.trigger == trigger && signalStruct.player == player )
			Signal( signalStruct, signal )
	}
}

void function DestroySignalStruct( SignalStruct singalStruct )
{
	file.signalStructArray.fastremovebyvalue( singalStruct )
}

void function Trophy_PlayerShieldUpdate( entity trigger, entity player )
{
	Assert ( IsNewThread(), "Must be threaded off." )

	printt( "STARTING SHIELD UPDATE FOR PLAYER " + player + " FOR TRIGGER " + trigger )
	//printt( "PLAYER " + player + " IS PHASESHIFTED: " + player.IsPhaseShifted() )

	// SignalStruct singalStruct = CreateSignalStruct( trigger, player )
	// EndSignal( singalStruct, "EndTacticalShieldRepair" )

	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	trigger.EndSignal( "OnDestroy" )

	entity pylon = trigger.GetOwner()

	while( trigger.IsTouching( player ) )
	{
		printt( "PLAYER " + player + " IS TOUCHING TRIGGER" )
		WaitFrame()

		// EmitSoundOnEntity( player, TROPHY_SHIELD_REPAIR_START )

		StatusEffect_AddEndless( player, eStatusEffect.trophy_shield_repair, 1 )
		
		// made get fx code from gas trap?
		// need to worry about server / client here
		//ShieldRepairVisualsEnabled( player, eStatusEffect.trophy_shield_repair, 1 )
		//TacticalChargeVisualsEnabled( player, eStatusEffect.trophy_shield_repair, 1 )

		//Release this player as a heal target.
		Trophy_ReleasePlayerAsHealTarget( pylon, player )
		if ( player.IsPlayer() )
			StatusEffect_Stop( player, eStatusEffect.trophy_shield_repair )
	}
}

void function Trophy_ReleasePlayerAsHealTarget( entity pylon, entity player )
{
	printt( "RELEASING PLAYER " + player + " AS HEAL TARGET FOR TRIGGER " + pylon )

	//HACK: UNTIL WE GET CODE FIX THAT PREVENTS PHASE SHIFTED CHARACTERS FROM TRIGGERING THE TRIGGER CALLBACK TWICE IN SUCESSION, WE NEED TO CHECK IF THE PLAYER IS A HEAL TARGET BECAUSE THEY CAN GET REMOVED TWICE IN SUCESSION.
	// if ( !file.deployableData[ droneMedic ].healTargets.contains( player ) )
	// 	return

	// Assert ( file.deployableData[ droneMedic ].healTargets.contains( player ), "Player is not a heal target." )
	// int index = file.deployableData[ droneMedic ].healTargets.find( player )
	// file.deployableData[ droneMedic ].healTargets.fastremove( index )
}

void function Trophy_ShieldUpdate( entity trigger, entity pylon )
{
	Assert ( IsNewThread(), "Must be threaded off." )
	trigger.EndSignal( "OnDestroy" )
	pylon.EndSignal( "OnDestroy" )

	OnThreadEnd(
		function() : ( pylon )
		{
			if ( IsValid( pylon ) )
			{
				StopSoundOnEntity( pylon, TROPHY_SHIELD_REPAIR_START )

				// array<HealData> healOverTimeArray = file.deployableData[ droneMedic ].healDataArray
				// foreach( healData in healOverTimeArray )
				// {
				// 	if ( IsValid( healData.healTarget ) )
				// 		EntityHealResource_Remove( healData.healTarget, healData.healResourceID )
				// }
				// file.deployableData[ droneMedic ].healDataArray.clear()
			}
		}
	)

	// int lastTargetCount     = DeployableMedic_GetHealTargetCount( trigger )
	// float droneMedicEndTime = Time() + DEPLOYABLE_MEDIC_MAX_LIFETIME
	/*
	while ( true )
	{
		//If we have heal targets
		array<entity> playerHealTargetArray = DeployableMedic_GetPlayerHealTargetArray( droneMedic )
		int targetCount                     = playerHealTargetArray.len()
		if ( targetCount != lastTargetCount )
		{
			//printt( "targetCount Differ", targetCount, lastTargetCount )
			int healResource = file.deployableData[ droneMedic ].healResource

			// cancel all heal in progress and start new ones as needed
			int newHealResource = 0
			bool healCanceled = false
			array<HealData> healDataArray = file.deployableData[ droneMedic ].healDataArray
			foreach( healData in healDataArray )
			{
				healCanceled = true
				if ( IsValid( healData.healTarget ) )
				{
					newHealResource += EntityHealResource_GetRemainingHeals( healData.healTarget, healData.healResourceID )
					EntityHealResource_Remove( healData.healTarget, healData.healResourceID )
				}
			}

			if ( healCanceled )
				healResource = newHealResource

			file.deployableData[ droneMedic ].healDataArray.clear()
			file.deployableData[ droneMedic ].healResource = healResource

			if ( targetCount && healResource > 0 )
			{
				int healAmount     = healResource / targetCount
				float healDuration = healAmount / DEPLOYABLE_MEDIC_HEAL_PER_SEC
				//droneMedicEndTime  = Time() + healDuration

				foreach( player in playerHealTargetArray )
				{
					if ( !IsValid( player ) || !player.IsPlayer() )
						continue

					float healPerSec = healAmount / healDuration
					HealData healData
					healData.healTarget = player
					healData.healResourceID = EntityHealResource_Add( player, healDuration, healPerSec, 0, "mp_weapon_deployable_medic", droneMedic.GetOwner() )
					Assert( healData.healResourceID != ENTITY_HEAL_RESOURCE_INVALID )
					file.deployableData[ droneMedic ].healDataArray.append( healData )
				}
			}
			//else
			//{
			//	float healResourceFrac = healResource / float( DEPLOYABLE_MEDIC_HEAL_AMOUNT )
			//	droneMedicEndTime = Time() + max( DEPLOYABLE_MEDIC_MAX_LIFETIME * healResourceFrac, DEPLOYABLE_MEDIC_MIN_LIFETIME )
			//	//printt( "Additional lifetime", max( DEPLOYABLE_MEDIC_MAX_LIFETIME * healResourceFrac, DEPLOYABLE_MEDIC_MIN_LIFETIME ) )
			//}
		}

		//Set skin index based on amount of heal resource left.
		//In the end it would be good to have an in-world bar on the device that drains as the heal resource is used up.

		float resourceFrac = file.deployableData[ droneMedic ].healResource / float( DEPLOYABLE_MEDIC_HEAL_AMOUNT )
		droneMedic.SetSoundCodeControllerValue( resourceFrac * 100.0 )

		//if ( resourceFrac >= 0.66 )
		//	droneMedic.SetSkin( DEPLOYABLE_MEDIC_RESOURCE_FULL_SKIN_INDEX )
		//else if ( resourceFrac >= 0.33 )
		//	droneMedic.SetSkin( DEPLOYABLE_MEDIC_RESOURCE_HALF_SKIN_INDEX )
		//else
		//	droneMedic.SetSkin( DEPLOYABLE_MEDIC_RESOURCE_LOW_SKIN_INDEX )

		//if we have exausted our heal resource or run out of time, end our update.
		if ( ( targetCount == 0 && Time() > droneMedicEndTime ) || file.deployableData[ droneMedic ].healResource <= 0 )
		{
			array<HealData> healDataArray = file.deployableData[ droneMedic ].healDataArray
			foreach( healData in healDataArray )
			{
				// due to health being an int and time a float we sometimes have a tiny bit more health left to add before we are done
				entity target = healData.healTarget
				if ( IsAlive( target ) )
				{
					int remainingHeal = EntityHealResource_GetRemainingHeals( target, healData.healResourceID )
					int currentHealth = target.GetHealth()
					int finalHealth = minint( target.GetMaxHealth(), currentHealth + remainingHeal )
					target.SetHealth( finalHealth )

					// todo(dw): I'm pretty sure this whole part of dishing out the final heal amounts is unnecessary (and complicates this stat hook)
					int diff = finalHealth - currentHealth
					if ( diff > 0 )
						StatsHook_MedicDeployableDrone_OnEntityHealResourceFinished( target, diff, "mp_weapon_deployable_medic", droneMedic.GetOwner() )
				}
			}

			droneMedic.Signal( "DeployableMedic_HealDepleated" )
			return
		}

		if ( targetCount == 0 && lastTargetCount > 0 )
		{
			StopSoundOnEntity( droneMedic, DEPLOYABLE_MEDIC_HEAL_LOOP_SOUND_3P )
		}
		else if ( targetCount > 0 && lastTargetCount == 0 )
		{
			EmitSoundOnEntity( droneMedic, DEPLOYABLE_MEDIC_HEAL_LOOP_SOUND_3P )
		}

		lastTargetCount = targetCount
		WaitFrame()
	}
	*/
}

#endif //SERVER



// GARBAGE COLLECTION
#if SERVER
// Copied from sh_loot_creeps.gnut, sets this up to take damage and die
void function TrophyDeathSetup( entity pylon )
{
	// todo: fix this later

	array <string> deathSounds
	deathSounds.append( TROPHY_DESTROY_SOUND )
	asset deathFx = TROPHY_DESTROY_FX

	array<string> lootToSpawn // adding this in to hopefully prevent crashes while working

	AddEntityCallback_OnDamaged( pylon,
		void function ( entity pylon, var damageInfo ) : ( lootToSpawn, deathSounds, deathFx )
		{
			if ( !IsValid( pylon ) )
				return

			if ( pylon.e.isDisabled ) //already in the process of being killed
				return

			float damage = DamageInfo_GetDamage( damageInfo )
			int damageSourceId = DamageInfo_GetDamageSourceIdentifier( damageInfo )
			if ( !IsValid( damageSourceId ) )
				return

			switch( damageSourceId )
			{
				case eDamageSourceId.mp_weapon_frag_grenade:
				case eDamageSourceId.mp_weapon_grenade_emp:
					if ( damage < 40 )
						return
				break

		}

			entity attacker = DamageInfo_GetAttacker( damageInfo )
			bool markedForDeath = false

			// the heck is marked for death
			if ( damageSourceId == eDamageSourceId.damagedef_despawn )
				markedForDeath = true

			else if ( IsValid( attacker ) && attacker.IsPlayer())
				markedForDeath = true

			if ( !markedForDeath )
				return

			pylon.e.isDisabled = true

			foreach( sound in deathSounds)
				EmitSoundAtPosition( TEAM_ANY, pylon.GetOrigin(), sound )

			thread CreateAirShake( pylon.GetOrigin(), 2, 50, 1 )
			int attach_id = pylon.LookupAttachment( "REF" )
			vector effectOrigin = pylon.GetAttachmentOrigin( attach_id )
			vector effectAngles = pylon.GetAttachmentAngles( attach_id )
			StartParticleEffectOnEntity( pylon, GetParticleSystemIndex( deathFx ), FX_PATTACH_POINT_FOLLOW, attach_id )
			pylon.Hide()
			pylon.NotSolid()
			pylon.Destroy()

		}
	)

}

void function TrophyDefenseGarbageCollect()
{
	print("Garbage collecting the pylons!")
	foreach( pp in file.trophyDefenseSystems )
	{
		if ( !IsValid( pp ) )
		{
			file.trophyDefenseSystems.fastremovebyvalue( pp )
			continue
		}

	if ( ShouldGarbageCollectTrophy( pp ) )
		{
			file.trophyDefenseSystems.fastremovebyvalue( pp )
			pp.Destroy()
		}
	}

	file.numActiveTrophyDefenseSystems = file.trophyDefenseSystems.len()
	file.lastTimeTrophyDefenseSystemsGarbageCollected = Time()
}

bool function ShouldGarbageCollectTrophy( entity trophy )
{
	print("Checking to see if this is a valid target to GC")
	/* i am way too tired to implement this
	vector origin = trophy.GetOrigin()

	if ( !SURVIVAL_PosInsideDeathField( origin ) )
		return true

	//no players nearby?
	const float maxDistSqr = 4000 * 4000
	bool playerNearby = false
	foreach( guy in GetPlayerArray_AliveConnected() )
	{
		float distanceSqr = Distance2DSqr( guy.GetOrigin(), origin )
		if ( distanceSqr < maxDistSqr )
			return false
	}

	return true
	*/
	return false
}
#endif

#if CLIENT
void function Trophy_OnWeaponStatusUpdate( entity player, var rui, int slot )
{
	if ( slot != OFFHAND_TACTICAL )
		return

	entity tacticalWeapon = player.GetOffhandWeapon( OFFHAND_TACTICAL )
	if ( !IsValid( tacticalWeapon ) )
		return

	string weaponName = tacticalWeapon.GetWeaponClassName()
	if ( weaponName != "mp_weapon_tesla_trap" )
		return

	bool activeSuperChargeApplied = tacticalWeapon.HasMod( "interception_pylon_super_charge" )
	RuiSetBool( rui, "rechargeBoosted", activeSuperChargeApplied )
}
#endif


#if CLIENT
void function Trophy_OnPropScriptCreated( entity ent )
{
	// not sure how to actually run / implement this
	// printl("placing on map")
	thread Trophy_CreateHUDMarker( ent )

}

void function Trophy_CreateHUDMarker( entity trophy )
{
	trophy.EndSignal( "OnDestroy" )

	entity localViewPlayer = GetLocalViewPlayer()
	if ( !Trophy_ShouldShowIcon( localViewPlayer, trophy ) )
		return

	vector pos = trophy.GetOrigin() + ( trophy.GetUpVector() * TROPHY_ICON_HEIGHT )
	var rui = CreateCockpitRui( $"ui/dirty_bomb_marker_icons.rpak", RuiCalculateDistanceSortKey( localViewPlayer.EyePosition(), pos ) )
	RuiSetGameTime( rui, "startTime", Time() )
	RuiTrackFloat3( rui, "pos", trophy, RUI_TRACK_OVERHEAD_FOLLOW )
	RuiKeepSortKeyUpdated( rui, true, "pos" )

	asset icon = $"rui/hud/ultimate_icons/ultimate_wattson_in_world"

	RuiSetImage( rui, "bombImage", icon )
	RuiSetImage( rui, "triggeredImage", icon )

	OnThreadEnd(
		function() : ( rui )
		{
			RuiDestroy( rui )
		}
	)

	WaitForever()
}

bool function Trophy_ShouldShowIcon( entity localViewPlayer, entity trapProxy )
{
	entity owner = trapProxy.GetBossPlayer()

	if ( !IsValid( owner ) )
		return false

	if ( localViewPlayer.GetTeam() != owner.GetTeam() )
		return false

	if ( !GamePlayingOrSuddenDeath() )
		return false

	printl("valid")
	return true
}

void function TacticalChargeVisualsEnabled( entity ent, int statusEffect, bool actuallyChanged )
{
	if ( ent != GetLocalViewPlayer() )
		return

	entity player = ent

	entity cockpit = player.GetCockpit()
	if ( !IsValid( cockpit ) )
		return

	thread TacticalChargeFXThink( player, cockpit )
}

void function TacticalChargeVisualsDisabled( entity ent, int statusEffect, bool actuallyChanged )
{
	if ( ent != GetLocalViewPlayer() )
		return

	ent.Signal( "EndTacticalChargeRepair" )
}

void function TacticalChargeFXThink( entity player, entity cockpit )
{
	player.EndSignal( "EndTacticalChargeRepair" )
	player.EndSignal( "OnDeath" )
	cockpit.EndSignal( "OnDestroy" )

	entity tacticalWeapon = player.GetOffhandWeapon( OFFHAND_TACTICAL )

	if ( !IsValid( tacticalWeapon ) )
		return

	string weaponName = tacticalWeapon.GetWeaponClassName()
	if ( weaponName != "mp_weapon_tesla_trap" )
		return

	tacticalWeapon.EndSignal( "OnDestroy" )

	OnThreadEnd(
		function() : ()
		{
			if ( !EffectDoesExist( file.tacticalChargeFXHandle ) )
				return

			EffectStop( file.tacticalChargeFXHandle, false, true )
		}
	)

	for ( ;; )
	{
		if ( !EffectDoesExist( file.tacticalChargeFXHandle ) )
		{
			file.tacticalChargeFXHandle = StartParticleEffectOnEntity( cockpit, GetParticleSystemIndex( TACTICAL_CHARGE_FX ), FX_PATTACH_ABSORIGIN_FOLLOW, -1 )
			EffectSetIsWithCockpit( file.tacticalChargeFXHandle, true )
			EmitSoundOnEntity( player, TROPHY_TACTICAL_CHARGE_SOUND )
		}

		vector controlPoint = <1,1,1>
		EffectSetControlPointVector( file.tacticalChargeFXHandle, 1, controlPoint )
		WaitFrame()
	}
}


void function ShieldRepairVisualsEnabled( entity player, int statusEffect, bool actuallyChanged )
{
	if ( player == GetLocalViewPlayer() )
	{
		EmitSoundOnEntity( player, TROPHY_SHIELD_REPAIR_START )
		return
	}

	thread TacticalShieldRepairFXStart( player )
}

void function ShieldRepairVisualsDisabled( entity player, int statusEffect, bool actuallyChanged )
{
	if ( player == GetLocalViewPlayer() )
	{
		if ( player.GetShieldHealth() == player.GetShieldHealthMax() )
			EmitSoundOnEntity( player, TROPHY_SHIELD_REPAIR_END )
	}

	player.Signal( "EndTacticalShieldRepair" )
}

void function TacticalShieldRepairFXStart( entity player )
{
	player.Signal( "EndTacticalShieldRepair" )
	player.EndSignal( "EndTacticalShieldRepair" )
	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )

	int oldArmorTier = -1
	int attachID         = player.LookupAttachment( "CHESTFOCUS" )
	int shieldChargeFXID = GetParticleSystemIndex( TROPHY_PLAYER_SHIELD_CHARGE_FX )
	int fxID = StartParticleEffectOnEntity( player, shieldChargeFXID, FX_PATTACH_POINT_FOLLOW, attachID )

	OnThreadEnd(
		function() : ( fxID )
		{
			if ( EffectDoesExist( fxID ) )
				EffectStop( fxID, true, true )
		}
	)

	while( true )
	{
		int armorTier = EquipmentSlot_GetEquipmentTier( player, "armor" )
		if ( armorTier != oldArmorTier )
		{
			oldArmorTier = armorTier
			vector shieldColor = GetFXRarityColorForTier( armorTier )
			EffectSetControlPointVector( fxID, 2, shieldColor )
		}

		WaitSignal( player, "UpdateShieldRepair" )
	}
}

void function ArmorChanged( entity player, string equipSlot, int new )
{
	player.Signal( "UpdateShieldRepair" )
}
#endif //
