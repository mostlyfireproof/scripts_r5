# Apex Legends Map Editor

![](https://i.imgur.com/Ib3E6qz.png)


### Getting started:
1. Download this repo and replace your current scripts (back them up first if you have changed anything you want to keep).
2. Go to:
    ```
    C:\Users\%username%\Saved Games\Respawn\Apex_fnf\local
    ```
    and make a backup of your `settings.cfg` file.
3. Launch game in dev mode.
4. Press ` key to open the console then enter this bind command:

    ```
        bind X "loadouts_devset character_selection character_pathfinder; ToggleThirdPerson; ToggleHUD; give mp_weapon_editor"; bind V "+offhand1"; bind T "ToggleThirdPerson"; bind F "noclip"; bind Q "+reload"; bind E "+use"; bind 3 "weapon_inspect"; bind 4 "+scriptCommand1"; bind 5 "+scriptCommand6"; bind R "+pushtotalk"; bind 6 "+offhand3"; bind Z "weaponSelectOrdnance"; bind G "+offhand4"
    ```

    * (Optional) This command is to bind F5 to refresh a map after making a change:

        `bind F5 "changelevel <map>"`

        Replace `<map>` with the actual map's name.

        For example: 

        ```
        bind F5 "changelevel mp_rr_desertlands_64k_x_64k"
        ```

        You can also bind other keys to other map names as well.

    (When you are finished using the map editor and want to go back to your regular binds, replace your `settings.cfg` file with the backup you made)
5. Now press `X` and then `V` to start editing.

### Keybinds:
* `X` Receive Prop Tool, change legend to Pathfinder, switch to TPP, and disable HUD.
* `V` Activate Prop Tool.
* `T` Change perspective mode.
* `F` Toggle noclip.
* `G` Zipline (double tap X to unequip)
* `MOUSE1` Place prop.
* `E` Cycle to next prop.
* `Q` Cycle to previous prop.
* `1` Raise prop.
* `2` Lower prop.
* `3` Change Yaw (z).
* `4` Change Pitch (y).
* `5` Change Roll (x).
* `R` Reset Prop Positions (x,y,z)
* `6` Change snap size.
* `Z` Open the model menu.

### Saving and loading:
* Before you start editing, open the console
    * To allow the info to print to the console, run `sq_showvmoutput 3`
* [To save and load, use the tool and follow the instructions here](https://github.com/mostlyfireproof/R5Edit)
* __PLEASE SAVE FREQUENTLY__, as the game can and will crash at the worst possible time
* To use the map when hosting, copy the `mp_rr_<map>_common.nut` somewhere else (like your desktop), install the scripts with which you will host, then copy it back in

### Known Issues:
* You can't go in to the prop menu when the zipline is equipped (unintended feature).
* Doesn't work on KC S2 or Ash's Redemption.
* If you run in to issues with this version, you can roll back to [this latest working version](https://github.com/mostlyfireproof/scripts_r5/tree/7937d332a1cc8948296addf1df978468e3a86b8e)
--------------------------------------

### Credits:
* [Peb](https://github.com/Vysteria)
* [JANU](https://github.com/EladNLG)
* [Sal](https://github.com/salcodes1)
* [Korboy](https://github.com/korboybeats)
* Shout out to [M1kep](https://github.com/M1kep) and Bogass for help as well
