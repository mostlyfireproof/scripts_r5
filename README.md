# R5Reloaded In-Game Level Editor

## This tool is in beta. It is not complete. 
## We do not take responsibility for any mental or physical harm caused by downloading, using, or modifying the level editor.

If you have any bugs, suggestions, or questions, create an issue at the [R5Edit repo](https://github.com/mostlyfireproof/R5Edit) 

### Getting started:
1. Download this repo and replace your current scripts
    1. back them up first if you have changed anything you want to keep
2. Load in to a game in debug mode
3. Press esc or tab, go to the dev menu, select Editor then Start Editing
4. Press q (your tactical button) to equip the tool

### Using the tool:
* Set the rotate and snap binds by running `bind "j" "+scriptCommand1"; bind "k" "+scriptCommand6"; bind "l" "+offhand3"` in the console
    * You can change j, k, and l to keys of your choice
* If you use toggle zoom, you need to bind something to hold aim to change props
* Press b (change fire mode) to enter delete mode

### Saving and loading:
* Before you start editing, open the console
* [To save and load, use the tool and follow the instructions here](https://github.com/mostlyfireproof/R5Edit)
* __PLEASE SAVE FREQUENTLY__, as the game can and will crash at the worst possible time
* To use the map when hosting, copy the `mp_rr_<map>_common.nut` somewhere else (like your desktop), install the scripts with which you will host, then copy it back in

### Known Issues:
* You can't go in to the prop menu when the zipline is equipped (unintended feature)
* Doesn't work on KC S2