global function ServerToUI_OpenModelMenu


struct
{
	var                       panel
	array<var>                buttons
	table<var, ItemFlavor>    buttonToCategory

	var miscCustomizeButton
} file

void function ServerToUI_OpenModelMenu() {
	printl("Opening model menu")
	OpenModelMenu()
}