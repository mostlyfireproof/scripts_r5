global function EditorModePlace_Init

global function ServerCallback_NextProp
global function ServerCallback_PreviousProp
global function ServerCallback_ResetProp
global function ServerCallback_OpenModelMenu
#if SERVER
global function GetPlacedProps
#endif
#if SERVER
global function ClientCommand_Model
global function ClientCommand_Spawnpoint

global function ClientCommand_UP_Server
global function ClientCommand_DOWN_Server
#elseif CLIENT
global function ClientCommand_UP_Client
global function ClientCommand_DOWN_Client
global function SetEquippedSection
#endif


struct {
    float offsetZ = 0
	array<var> inputHintRuis	

    table< string, vector > displacements = {} 
    array< string >         displacementKeys = []

    #if SERVER
    table<entity, float> snapSizes
    table<entity, float> pitches
    table<entity, float> yaws
    table<entity, float> rolls
    table<entity, float> offsets
    array<entity> allProps
    #elseif CLIENT
    float snapSize = 4
    float pitch = 0
    float yaw = 0
    float roll = 0
    #endif
} file
#if SERVER
array<entity> function GetPlacedProps()
{
    return file.allProps
}
#endif
EditorMode function EditorModePlace_Init() 
{
    // INIT FOR WEAPON

    EditorMode mode

    mode.displayName = "Place"
    mode.description = "Place props one by one"
    
    mode.onActivationCallback = EditorModePlace_Activation
    mode.onDeactivationCallback = EditorModePlace_Deactivation
    mode.onAttackCallback = EditorModePlace_Place

    // END INIT FOR WEAPON

    // FILE LEVEL INIT
    file.displacements["mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl"] <- <0, 0, 0>
    file.displacements["mdl/thunderdome/thunderdome_cage_ceiling_256x256_06.rmdl"] <- <128, 0, 0>
    file.displacements["mdl/Humans/class/medium/combat_dummie_medium.rmdl"] <- <0, 0, 0>
    
    foreach(disp, ign in file.displacements) {
        file.displacementKeys.append(disp)
    }

    // save and load functions
    #if SERVER
    AddClientCommandCallback("model", ClientCommand_Model)
    AddClientCommandCallback("compile", ClientCommand_Compile)
    AddClientCommandCallback("load", ClientCommand_Load)
    AddClientCommandCallback("spawnpoint", ClientCommand_Spawnpoint)
    AddClientCommandCallback("nextprop", ClientCommand_Next)
    AddClientCommandCallback("previousprop", ClientCommand_Previous) 
    AddClientCommandCallback("resetprop", ClientCommand_Reset)  
    AddClientCommandCallback("section", ClientCommand_Section)
    #endif

    // in-editor functions
    #if CLIENT
    // should not be here. wait until weapon is equipped.
    //RegisterConCommandTriggeredCallback( "weaponSelectPrimary0", ClientCommand_UP_Client )
    //RegisterConCommandTriggeredCallback( "weaponSelectPrimary1", ClientCommand_DOWN_Client )
    #elseif SERVER
    AddClientCommandCallback( "moveUp", ClientCommand_UP_Server )
    AddClientCommandCallback( "moveDown", ClientCommand_DOWN_Server )
    AddClientCommandCallback( "ChangeSnapSize", ChangeSnapSize )
    AddClientCommandCallback( "ChangePitchRotation", ChangePitchRotation )
    AddClientCommandCallback( "ChangeYawRotation", ChangeYawRotation )
    AddClientCommandCallback( "ChangeRollRotation", ChangeRollRotation )
    #endif


    // AddClientCommandCallback("rotate", ClientCommand_Rotate)
    // AddClientCommandCallback("undo", ClientCommand_Undo)

    // END FILE INIT

    return mode
}

void function EditorModePlace_Activation(entity player)
{   
    #if CLIENT
    foreach( rui in startEditorRUIs )
    {
        RuiDestroy( rui )
    }
    startEditorRUIs.clear()
    #endif

    AddInputHint( "%B%", "Change Editor Mode" )
    AddInputHint( "%T%", "Change Perspective" )
    AddInputHint( "%F%", "NoClip")  
    AddInputHint( "%G%", "Zipline")
    AddInputHint( "", "")
    AddInputHint( "%attack%", "Place Prop" )
    AddInputHint( "%E%", "Next Prop")
    AddInputHint( "%Q%", "Previous Prop")
    AddInputHint( "%1%", "Raise" )
    AddInputHint( "%2%", "Lower" )
    AddInputHint( "%3%", "Change Yaw (z)" )
    AddInputHint( "%4%", "Change Pitch (y)" )
    AddInputHint( "%5%", "Change Roll (x)" )
    AddInputHint( "%R%", "Reset Prop Positions (x,y,z)" )
    AddInputHint( "%6%", "Change Snap Size" ) // no calling in a titanfall because of this
    AddInputHint( "%Z%", "Open Model Menu" )   
    
    #if CLIENT
    
    //RegisterConCommandTriggeredCallback( "+use", ServerCallback_NextProp)
    //RegisterConCommandTriggeredCallback( "+reload", ServerCallback_PreviousProp)
    RegisterConCommandTriggeredCallback( "+pushtotalk", ServerCallback_ResetProp)
    RegisterConCommandTriggeredCallback( "weaponSelectPrimary0", ClientCommand_UP_Client )
    RegisterConCommandTriggeredCallback( "weaponSelectPrimary1", ClientCommand_DOWN_Client )
    RegisterConCommandTriggeredCallback( "+scriptCommand6", SwapToNextRoll )
    RegisterConCommandTriggeredCallback( "+scriptCommand1", SwapToNextPitch )
    RegisterConCommandTriggeredCallback( "weapon_inspect", SwapToNextYaw )
    RegisterConCommandTriggeredCallback( "+offhand3", SwapToNextSnapSize )
    RegisterConCommandTriggeredCallback( "weaponSelectOrdnance", ServerCallback_OpenModelMenu )

    #elseif SERVER

    AddButtonPressedPlayerInputCallback( player, IN_USE, ServerCallback_NextProp )
    AddButtonPressedPlayerInputCallback( player, IN_RELOAD, ServerCallback_PreviousProp )
    //AddButtonPressedPlayerInputCallback( player, IN_MELEE, ServerCallback_ResetProp )
    
    if( !(player in file.snapSizes) )
    {
        file.snapSizes[player] <- 4
    }
    if( !(player in file.pitches) )
    {
        file.pitches[player] <- 0
    }
    if( !(player in file.yaws) )
    {
        file.yaws[player] <- 0
    }
    if( !(player in file.offsets) )
    {
        file.offsets[player] <- 0
    }
    if( !(player in file.rolls) )
    {
        file.rolls[player] <- 0
    }
    if( !(player in file.offsets) )
    {
        file.offsets[player] <- 0
    }
    #endif

    if(player.p.selectedProp.section == "")
    {
        player.p.selectedProp = NewPropInfo("mdl/base_models", 0)
    }
    
    StartNewPropPlacement(player)
}

void function EditorModePlace_Deactivation(entity player)
{
    RemoveAllHints()
    #if CLIENT
    // deregister here so no errors. 
    // we're also deregistering so we don't change the z offset while we are doing something else e.g. playtesting.
    // should also use +scriptCommands. Seriously.

    //DeregisterConCommandTriggeredCallback( "+use", ServerCallback_NextProp)
    //DeregisterConCommandTriggeredCallback( "+reload", ServerCallback_PreviousProp)
    DeregisterConCommandTriggeredCallback( "+pushtotalk", ServerCallback_ResetProp)
    DeregisterConCommandTriggeredCallback( "weaponSelectPrimary0", ClientCommand_UP_Client )
    DeregisterConCommandTriggeredCallback( "weaponSelectPrimary1", ClientCommand_DOWN_Client )
    DeregisterConCommandTriggeredCallback( "+scriptCommand6", SwapToNextRoll )
    DeregisterConCommandTriggeredCallback( "+scriptCommand1", SwapToNextPitch )
    DeregisterConCommandTriggeredCallback( "weapon_inspect", SwapToNextYaw ) 
    DeregisterConCommandTriggeredCallback( "+offhand3", SwapToNextSnapSize )
    DeregisterConCommandTriggeredCallback( "weaponSelectOrdnance",  ServerCallback_OpenModelMenu )

    AddActivatePropToolHint()

    #elseif SERVER

    RemoveButtonPressedPlayerInputCallback( player, IN_USE, ServerCallback_NextProp )
    RemoveButtonPressedPlayerInputCallback( player, IN_RELOAD, ServerCallback_PreviousProp )
    //RemoveButtonPressedPlayerInputCallback( player, IN_MELEE, ServerCallback_ResetProp )

    #endif
    if(IsValid(GetProp(player)))
    {
        GetProp(player).Destroy()
    }
}

void function EditorModePlace_Place(entity player)
{
    PlaceProp(player)
    StartNewPropPlacement(player)
}



void function RemoveAllHints()
{
    #if CLIENT
    foreach( rui in file.inputHintRuis )
    {
        RuiDestroy( rui )
    }
    file.inputHintRuis.clear()
    #endif
}

void function AddInputHint( string buttonText, string hintText)
{

    #if CLIENT
    var hintRui = CreateFullscreenRui( $"ui/tutorial_hint_line.rpak" )

	RuiSetString( hintRui, "buttonText", buttonText )
	// RuiSetString( hintRui, "gamepadButtonText", gamePadButtonText )
	RuiSetString( hintRui, "hintText", hintText )
	// RuiSetString( hintRui, "altHintText", altHintText )
	RuiSetInt( hintRui, "hintOffset", file.inputHintRuis.len() )
	// RuiSetBool( hintRui, "hideWithMenus", false )

    file.inputHintRuis.append( hintRui )

    #endif
}

void function ServerCallback_OpenModelMenu( entity player ) {
    #if SERVER
        Remote_CallFunction_Replay( player, "ServerCallback_OpenModelMenu", player )
    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;
    player = GetLocalClientPlayer()
    
    if (!IsValid(player)) return
    if (!IsAlive(player)) return
    
    RunUIScript("OpenModelMenu", player.p.selectedProp.section)
    #endif
}

void function ServerCallback_NextProp( entity player )
{
    #if CLIENT
    if(player != GetLocalClientPlayer()) return;
    player = GetLocalClientPlayer()
    #endif

    if(!IsValid( player )) return
    if(!IsAlive( player )) return

    int max = GetAssets()[player.p.selectedProp.section].len()
    if (player.p.selectedProp.index + 1 > max - 1) {
        player.p.selectedProp.index = 0
    } else {
        player.p.selectedProp.index++
    }

    #if CLIENT
    UpdateRUI(player)
    #endif

    #if SERVER
        Remote_CallFunction_Replay( player, "ServerCallback_NextProp", player )
    #endif
}

void function ServerCallback_PreviousProp( entity player )
{
    #if CLIENT
    if(player != GetLocalClientPlayer()) return;
    player = GetLocalClientPlayer()
    #endif

    if(!IsValid( player )) return
    if(!IsAlive( player )) return

    int max = GetAssets()[player.p.selectedProp.section].len()
    if (player.p.selectedProp.index - 1 < 0) {
        player.p.selectedProp.index = max - 1
    } else {
        player.p.selectedProp.index--
    }

    #if CLIENT
    UpdateRUI(player)
    #endif

    #if SERVER
        Remote_CallFunction_Replay( player, "ServerCallback_PreviousProp", player )
    #endif
}

void function ServerCallback_ResetProp( entity player )
{
    #if CLIENT
    if (player != GetLocalClientPlayer()) return;
    switch (file.pitch)
    {
            default:
            file.pitch = 0
            player.ClientCommand( "ChangePitchRotation 0" )
            break;  
    }
    #endif

    #if CLIENT
    if (player != GetLocalClientPlayer()) return;
    switch (file.yaw)
    {
            default:
            file.yaw = 0
            player.ClientCommand( "ChangeYawRotation 0" )
            break;  
    }
    #endif

    #if CLIENT
    if (player != GetLocalClientPlayer()) return;
    switch (file.roll)
    {
            default:
            file.roll = 0
            player.ClientCommand( "ChangeRollRotation 0" )
            break;  
    }
    #endif
}



void function StartNewPropPlacement(entity player)
{
    // incoming
    #if SERVER
    SetProp(player, CreatePropDynamic( GetAssetFromPlayer(player), <0, 0, file.offsets[player]>, <0, 0, 0>, SOLID_VPHYSICS ))
    GetProp(player).NotSolid()
    GetProp(player).Hide()
    
    #elseif CLIENT
	SetProp(player, CreateClientSidePropDynamic( <0, 0, file.offsetZ>, <0, 0, 0>, GetAssetFromPlayer(player) ))
    DeployableModelWarningHighlight( GetProp(player) )
    
	GetProp(player).kv.renderamt = 255
	GetProp(player).kv.rendermode = 3
	GetProp(player).kv.rendercolor = "255 255 255 255"

    #endif

    thread PlaceProxyThink(player)


    
}

void function PlaceProp(entity player)
{
    #if SERVER
    file.allProps.append(GetProp(player))
    GetProp(player).Show()
    GetProp(player).Solid()
    GetProp(player).AllowMantle()
    GetProp(player).SetScriptName("editor_placed_prop")
    
    // prints prop info to the console to save it
    vector myOrigin = GetProp(player).GetOrigin()
    vector myAngles = GetProp(player).GetAngles()

    string positionSerialized = myOrigin.x.tostring() + "," + myOrigin.y.tostring() + "," + myOrigin.z.tostring()
	string anglesSerialized = myAngles.x.tostring() + "," + myAngles.y.tostring() + "," + myAngles.z.tostring()
    printl("[editor]" + string(GetAssetFromPlayer(player)) + ";" + positionSerialized + ";" + anglesSerialized)

    #elseif CLIENT
    if(player != GetLocalClientPlayer()) return;
    GetProp(player).Destroy()
    SetProp(player, null)
    #endif
}

int counter = 0
void function PlaceProxyThink(entity player)
{
    float gridSize = 256

    while( IsValid( GetProp(player) ) )
    {
        #if CLIENT
        gridSize = file.snapSize
        #elseif SERVER
        gridSize = file.snapSizes[player]
        #endif
        if(!IsValid( player )) return
        if(!IsAlive( player )) return

        GetProp(player).SetModel( GetAssetFromPlayer(player) )

	    TraceResults result = TraceLine(player.EyePosition() + 5 * player.GetViewForward(), player.GetOrigin() + 200 * player.GetViewForward(), [player], TRACE_MASK_SHOT, TRACE_COLLISION_GROUP_PLAYER)

        vector origin = result.endPos
        origin.x = RoundToNearestInt(origin.x / gridSize) * gridSize
        origin.y = RoundToNearestInt(origin.y / gridSize) * gridSize
        origin.z = (RoundToNearestInt(origin.z / gridSize) * gridSize)
        #if CLIENT
        origin.z += file.offsetZ
        #elseif SERVER
        origin.z += file.offsets[player]
        #endif
        
        vector offset = player.GetViewForward()
        
        // convert offset to -1 if value it's less than -0.5, 0 if it's between -0.5 and 0.5, and 1 if it's greater than 0.5

        vector ang = VectorToAngles(player.GetViewForward())

        float functionref(float val, float x, float y) smartClamp = float function(float val, float x, float y)
        {
            // clamp val circularly between x and y, which can be negative
            if(val < x)
            {
                return val + (y - x)
            }
            else if(val > y)
            {
                return val - (y - x)
            }
            return val
        }

        ang.x = floor(smartClamp(ang.x + 45, -360, 360) / 90) * 90
        ang.y = floor(smartClamp(ang.y + 45, -360, 360) / 90) * 90
        ang.z = floor(smartClamp(ang.z + 45, -360, 360) / 90) * 90

        string assetName = string(GetAssetFromPlayer(player))
        if (contains(file.displacementKeys, assetName)) {
            offset = RotateVector(file.displacements[assetName], ang)
        }
        // offset.x = offset.x * player.p.selectedProp.originDisplacement.x
        // offset.y = offset.y * player.p.selectedProp.originDisplacement.y
        // offset.z = offset.z * player.p.selectedProp.originDisplacement.z

        origin = origin + offset
        

        vector angles = VectorToAngles( -1 * player.GetViewVector() )
        angles.x = GetProp(player).GetAngles().x
        angles.x = 0
        angles.y = floor(smartClamp(angles.y - 45, -360, 360) / 90) * 90
        #if CLIENT
        angles.z = (angles.z + file.pitch) % 360
        angles.y = (angles.y + file.yaw) % 360
        angles.x = (angles.x + file.roll) % 360
        #elseif SERVER
        angles.z = (angles.z + file.pitches[player]) % 360
        angles.y = (angles.y + file.yaws[player]) % 360
        angles.x = (angles.x + file.rolls[player]) % 360
        #endif

        GetProp(player).SetOrigin( origin )
        GetProp(player).SetAngles( angles )

        wait 0.01
    }
}

entity function GetProp(entity player)
{
    #if SERVER || CLIENT
    return player.p.currentPropEntity
    #endif
    return null
}

void function SetProp(entity player, entity prop)
{
    #if SERVER || CLIENT
    player.p.currentPropEntity = prop
    #endif
    return null
}

PropInfo function NewPropInfo(string section, int index)
{
    PropInfo prop
    prop.section = section
    prop.index = index
    return prop
}

#if SERVER
bool function ClientCommand_UP_Server(entity player, array<string> args)
{
    file.offsets[player] += 32
    printl("moving up " + file.offsets[player])
    return true
}

bool function ClientCommand_DOWN_Server(entity player, array<string> args)
{
    file.offsets[player] -= 32
    printl("moving down " + file.offsets[player])
    return true
}
bool function ChangeSnapSize( entity player, array<string> args )
{
    if (args[0] == "") return true
    
    if( !(player in file.snapSizes) )
    {
        file.snapSizes[player] <- args[0].tofloat()
    }
    file.snapSizes[player] = args[0].tofloat()

    return true
}

bool function ClientCommand_Section(entity player, array<string> args) {
    if (args.len() > 0) {
        if (contains(GetSections(), args[0])) {
            player.p.selectedProp.section = args[0]
            player.p.selectedProp.index = 0
        }
        return false
    }
    return false
}

bool function ChangePitchRotation( entity player, array<string> args )
{
    if (args[0] == "") return true
    
    printl(args[0].tofloat())
    if( !(player in file.pitches) )
    {
        file.pitches[player] <- args[0].tofloat()
    }
    file.pitches[player] = args[0].tofloat()

    return true
}

bool function ChangeYawRotation( entity player, array<string> args )
{
    if (args[0] == "") return true
    
    printl(args[0].tofloat())
    if( !(player in file.yaws) )
    {
        file.yaws[player] <- args[0].tofloat()
    }
    file.yaws[player] = args[0].tofloat()

    return true
}

bool function ChangeRollRotation( entity player, array<string> args )
{
    if (args[0] == "") return true
    
    printl(args[0].tofloat())
    if( !(player in file.rolls) )
    {
        file.rolls[player] <- args[0].tofloat()
    }
    file.rolls[player] = args[0].tofloat()

    return true
}
#elseif CLIENT

void function SwapToNextSnapSize(entity player)
{
    if (player != GetLocalClientPlayer()) return;
    switch (file.snapSize)
    {
        case 4:
            file.snapSize = 64
            player.ClientCommand( "ChangeSnapSize 64" )
            break;
        case 64:
            file.snapSize = 128
            player.ClientCommand( "ChangeSnapSize 128" )
            break;
        case 128:
            file.snapSize = 256
            player.ClientCommand( "ChangeSnapSize 256" )
            break;
        default:
            file.snapSize = 4
            player.ClientCommand( "ChangeSnapSize 4" )
            break;
    }
}

void function SwapToNextPitch(entity player)
{
    if (player != GetLocalClientPlayer()) return;
    switch (file.pitch)
    {
        case 0:
            file.pitch = 15
            player.ClientCommand( "ChangePitchRotation 15" )
            break;
        case 15:
            file.pitch = 30
            player.ClientCommand( "ChangePitchRotation 30" )
            break;
        case 30:
            file.pitch = 45
            player.ClientCommand( "ChangePitchRotation 45" )
            break;
        case 45:
            file.pitch = 60
            player.ClientCommand( "ChangePitchRotation 60" )
            break;
        case 60:
            file.pitch = 75
            player.ClientCommand( "ChangePitchRotation 75" )
            break;
        case 75:
        file.pitch = 90
            player.ClientCommand( "ChangePitchRotation 90" )
            break;
        case 90:
            file.pitch = 105
            player.ClientCommand( "ChangePitchRotation 105" )
            break;
        case 105:
            file.pitch = 120
            player.ClientCommand( "ChangePitchRotation 120" )
            break;
        case 120:
            file.pitch = 135
            player.ClientCommand( "ChangePitchRotation 135" )
            break;
        case 135:
            file.pitch = 150
            player.ClientCommand( "ChangePitchRotation 150" )
            break;
        case 150:
            file.pitch = 165
            player.ClientCommand( "ChangePitchRotation 165" )
            break;
        case 165:
            file.pitch = 180
            player.ClientCommand( "ChangePitchRotation 180" )
            break;
        case 180:
            file.pitch = 195
            player.ClientCommand( "ChangePitchRotation 195" )
            break;
        case 195:
            file.pitch = 210
            player.ClientCommand( "ChangePitchRotation 210" )
            break;
        case 210:
            file.pitch = 225
            player.ClientCommand( "ChangePitchRotation 225" )
            break;
        case 225:
            file.pitch = 240
            player.ClientCommand( "ChangePitchRotation 240" )
            break;
        case 240:
            file.pitch = 255
            player.ClientCommand( "ChangePitchRotation 255" )
            break;
        case 255:
            file.pitch = 270
            player.ClientCommand( "ChangePitchRotation 270" )
            break;
        case 270:
            file.pitch = 285
            player.ClientCommand( "ChangePitchRotation 285" )
            break;
        case 285:
            file.pitch = 300
            player.ClientCommand( "ChangePitchRotation 300" )
            break;
        case 300:
            file.pitch = 315
            player.ClientCommand( "ChangePitchRotation 315" )
            break;
        case 315:
            file.pitch = 330
            player.ClientCommand( "ChangePitchRotation 330" )
            break;
        case 330:
            file.pitch = 345
            player.ClientCommand( "ChangePitchRotation 345" )
            break;
        case 345:
            default:
            file.pitch = 0
            player.ClientCommand( "ChangePitchRotation 0" )
            break;
    }
}

// not fully implemented
void function SwapToNextYaw(entity player)
{
    if (player != GetLocalClientPlayer()) return;
    switch (file.yaw)
    {
        case 0:
            file.yaw = 15
            player.ClientCommand( "ChangeYawRotation 15" )
            break;
        case 15:
            file.yaw = 30
            player.ClientCommand( "ChangeYawRotation 30" )
            break;
        case 30:
            file.yaw = 45
            player.ClientCommand( "ChangeYawRotation 45" )
            break;
        case 45:
            file.yaw = 60
            player.ClientCommand( "ChangeYawRotation 60" )
            break;
        case 60:
            file.yaw = 75
            player.ClientCommand( "ChangeYawRotation 75" )
            break;
        case 75:
            file.yaw = 90
            player.ClientCommand( "ChangeYawRotation 90" )
            break;
        case 90:
            file.yaw = 105
            player.ClientCommand( "ChangeYawRotation 105" )
            break;
        case 105:
            file.yaw = 120
            player.ClientCommand( "ChangeYawRotation 120" )
            break;
        case 120:
            file.yaw = 135
            player.ClientCommand( "ChangeYawRotation 135" )
            break;
        case 135:
            file.yaw = 150
            player.ClientCommand( "ChangeYawRotation 150" )
            break;
        case 150:
            file.yaw = 165
            player.ClientCommand( "ChangeYawRotation 165" )
            break;
        case 165:
            file.yaw = 180
            player.ClientCommand( "ChangeYawRotation 180" )
            break;
        case 180:
            file.yaw = 195
            player.ClientCommand( "ChangeYawRotation 195" )
            break;
        case 195:
            file.yaw = 210
            player.ClientCommand( "ChangeYawRotation 210" )
            break;
        case 210:
            file.yaw = 225
            player.ClientCommand( "ChangeYawRotation 225" )
            break;
        case 225:
            file.yaw = 240
            player.ClientCommand( "ChangeYawRotation 240" )
            break;
        case 240:
            file.yaw = 255
            player.ClientCommand( "ChangeYawRotation 255" )
            break;
        case 255:
            file.yaw = 270
            player.ClientCommand( "ChangeYawRotation 270" )
            break;
        case 270:
            file.yaw = 285
            player.ClientCommand( "ChangeYawRotation 285" )
            break;
        case 285:
            file.yaw = 300
            player.ClientCommand( "ChangeYawRotation 300" )
            break;
        case 300:
            file.yaw = 315
            player.ClientCommand( "ChangeYawRotation 315" )
            break;
        case 315:
            file.yaw = 330
            player.ClientCommand( "ChangeYawRotation 330" )
            break;
        case 330:
            file.yaw = 345
            player.ClientCommand( "ChangeYawRotation 345" )
            break;
        case 345:
            default:
            file.yaw = 0
            player.ClientCommand( "ChangeYawRotation 0" )
            break;
    }
}

void function SwapToNextRoll(entity player)
{
    if (player != GetLocalClientPlayer()) return;
    switch (file.roll)
    {
        case 0:
            file.roll = 15
            player.ClientCommand( "ChangeRollRotation 15" )
            break;
        case 15:
            file.roll = 30
            player.ClientCommand( "ChangeRollRotation 30" )
            break;
        case 30:
            file.roll = 45
            player.ClientCommand( "ChangeRollRotation 45" )
            break;
        case 45:
            file.roll = 60
            player.ClientCommand( "ChangeRollRotation 60" )
            break;
        case 60:
            file.roll = 75
            player.ClientCommand( "ChangeRollRotation 75" )
            break;
        case 75:
            file.roll = 90
            player.ClientCommand( "ChangeRollRotation 90" )
            break;
        case 90:
            file.roll = 105
            player.ClientCommand( "ChangeRollRotation 105" )
            break;
        case 105:
            file.roll = 120
            player.ClientCommand( "ChangeRollRotation 120" )
            break;
        case 120:
            file.roll = 135
            player.ClientCommand( "ChangeRollRotation 135" )
            break;
        case 135:
            file.roll = 150
            player.ClientCommand( "ChangeRollRotation 150" )
            break;
        case 150:
            file.roll = 165
            player.ClientCommand( "ChangeRollRotation 165" )
            break;
        case 165:
            file.roll = 180
            player.ClientCommand( "ChangeRollRotation 180" )
            break;
        case 180:
            file.roll = 195
            player.ClientCommand( "ChangeRollRotation 195" )
            break;
        case 195:
            file.roll = 210
            player.ClientCommand( "ChangeRollRotation 210" )
            break;
        case 210:
            file.roll = 225
            player.ClientCommand( "ChangeRollRotation 225" )
            break;
        case 225:
            file.roll = 240
            player.ClientCommand( "ChangeRollRotation 240" )
            break;
        case 240:
            file.roll = 255
            player.ClientCommand( "ChangeRollRotation 255" )
            break;
        case 255:
            file.roll = 270
            player.ClientCommand( "ChangeRollRotation 270" )
            break;
        case 270:
            file.roll = 285
            player.ClientCommand( "ChangeRollRotation 285" )
            break;
        case 285:
            file.roll = 300
            player.ClientCommand( "ChangeRollRotation 300" )
            break;
        case 300:
            file.roll = 315
            player.ClientCommand( "ChangeRollRotation 315" )
            break;
        case 315:
            file.roll = 330
            player.ClientCommand( "ChangeRollRotation 330" )
            break;
        case 330:
            file.roll = 345
            player.ClientCommand( "ChangeRollRotation 345" )
            break;
        case 345:
            default:
            file.roll = 0
            player.ClientCommand( "ChangeRollRotation 0" )
            break;
    }
}

bool function ClientCommand_UP_Client(entity player)
{
    GetLocalClientPlayer().ClientCommand("moveUp")
    file.offsetZ += 32
    return true
}

bool function ClientCommand_DOWN_Client(entity player)
{
    GetLocalClientPlayer().ClientCommand("moveDown")
    file.offsetZ -= 32
    return true
}
#endif

bool function ClientCommand_Model(entity player, array<string> args) {
    /* 	
    if (args.len() < 1) {
		return false
 	}

 	try {
 		string modelName = args[0]
 	    file.buildProp = CastStringToAsset(modelName)
 		file.currentModelName = modelName
    } catch (error) {
 		printl(error)
 	}
    */
	return true
}

bool function ClientCommand_Rotate(entity player, array<string> args) {
    return true
}

bool function ClientCommand_Undo(entity player, array<string> args) {
    return true
}

// deleted createFRProp

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



TraceResults function PlayerLookingAtRes(entity player) {
    vector angles = player.EyeAngles()
	vector forward = AnglesToForward( angles )
	vector origin = player.EyePosition()

	vector start = origin
	vector end = origin + forward * 50000
	TraceResults result = TraceLine( start, end )

	return result
}

vector function PlayerLookingAtVec(entity player) {
    vector angles = player.EyeAngles()
	vector forward = AnglesToForward( angles )
	vector origin = player.EyePosition()

	vector start = origin
	vector end = origin + forward * 50000
	TraceResults result = TraceLine( start, end )

	return result.endPos
}

#if SERVER
bool function ClientCommand_Spawnpoint(entity player, array<string> args) {
    // if (file.currentEditor != null) {
    //     vector origin = player.GetOrigin()
    //     vector angles = player.GetAngles()

    //     LocPair pair = NewLocPair(origin, angles)
    //     file.spawnPoints.append(pair)
    //     printl("Successfully added position " + origin + " " + angles)
    //     SpawnDummyAtPlayer(player)
    // } else {
    //     printl("You must be in editor mode")
    //     return false
    // }
    return true
}

bool function ClientCommand_Next(entity player, array<string> args) {
    ServerCallback_NextProp(player)
    //Remote_CallFunction_Replay( player, "ServerCallback_NextProp", player )
    return true
}

bool function ClientCommand_Previous(entity player, array<string> args) {
    ServerCallback_PreviousProp(player)
    //Remote_CallFunction_Replay( player, "ServerCallback_PreviousProp", player )
    return true
}

bool function ClientCommand_Reset(entity player, array<string> args) {
    ServerCallback_ResetProp(player)
    //Remote_CallFunction_Replay( player, "ServerCallback_ResetProp", player )
    return true
}
#endif


// util funcs
// O(n) might need to be improved
string function getbyvalue(array<string> sec, string val) {
    foreach(p in sec) {
        if (val == p) {
            return val
        }
    }
    return ""
}
bool function contains(array<string> sec, string val) {
    foreach(p in sec) {
        if (val == p) {
            return true
        }
    }
    return false
}

asset function GetAssetFromPlayer(entity player) {
    string sec = player.p.selectedProp.section
    int index = player.p.selectedProp.index
    return GetAssets()[sec][index]
}

#if CLIENT
void function SetEquippedSection(string sec) {
    entity player = GetLocalClientPlayer()
    player.p.selectedProp.section = sec
    player.p.selectedProp.index = 0
    UpdateRUI(player)

    player.ClientCommand("section " + sec)
}
#endif
