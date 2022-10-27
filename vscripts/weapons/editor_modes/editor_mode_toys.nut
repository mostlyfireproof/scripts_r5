global function EditorModeToys_Init

EditorMode function EditorModeToys_Init() 
{
    EditorMode mode

    mode.displayName = "Toys"
    mode.description = "Place down various interactive props"
    mode.crosshairActive = true
    
    mode.onActivationCallback = EditorModeToys_Activation
    mode.onDeactivationCallback = EditorModeToys_Deactivation
    mode.onAttackCallback = EditorModeToys_Place


    return mode
}

struct {
    float offsetZ = 0
	array<var> inputHintRuis	

    table< string, vector > displacements = {} 
    array< string >         displacementKeys = []

    #if SERVER
    table<entity, float> snapSizes
    table<entity, float> pitches
    table<entity, float> yaws
    table<entity, float> offsets
    array<entity> allProps
    #elseif CLIENT
    float snapSize = 64
    float pitch = 0
    float yaw = 0
    #endif
} file



void function EditorModeToys_Activation(entity player)
{
    AddInputHint( "%B%", "Change Editor Mode" )
    AddInputHint( "%T%", "Change Perspective" )
    AddInputHint( "%F%", "NoClip")
    AddInputHint( "%G%", "Zipline")

    #if CLIENT
    foreach( rui in startEditorRUIs )
    {
        RuiDestroy( rui )
    }
    startEditorRUIs.clear()
    #endif

    #if CLIENT
    
    //RegisterConCommandTriggeredCallback( "+use", ServerCallback_NextProp)
    //RegisterConCommandTriggeredCallback( "+pushtotalk", ServerCallback_PreviousProp)

    #elseif SERVER

    //AddButtonPressedPlayerInputCallback( player, IN_USE, ServerCallback_NextProp )
    //AddButtonPressedPlayerInputCallback( player, IN_USE_ALT, ServerCallback_PreviousProp )

    if( !(player in file.snapSizes) )
    {
        file.snapSizes[player] <- 64
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
    #endif

    
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

void function EditorModeToys_Deactivation(entity player)
{
    RemoveAllHints() 
    #if CLIENT
    AddActivatePropToolHint()
    #endif  
}

void function EditorModeToys_Place(entity player)
{

}