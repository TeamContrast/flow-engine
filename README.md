# Flow Engine

A Rush/Advance-styled 2D sonic engine.  

## Features:

- Boosting
- Stomping
- Tricking, both in midair and on rails
- A charge-up spindash
- Slope physics
- Rings
- Basic enemies
- Spline-based rails
- Springs
- Boost rings (or air-dash rings or whatever you call them)

## Controls:

If Sonic is in a position where he could be air tricking, stomp is mapped to trick + down. Otherwise, it is mapped to just trick.

Keyboard:

* arrow keys - movement 

* Z - Jump 

* X - Boost 

* D - Trick

* R - Reset position

Controller:

* D-pad, Left stick - movement

* Xbox A - Jump

* Xbox X -Boost

* Xbox B - Trick

* Xbox Back - Reset position

\*Note: controller buttons for other controllers will be mapped to their same physical location on the controller, as per standard Godot mapping behavior

## How to use

* `demo_levels` can be entirely deleted at the user's discretion, as it only contains the demo levels and their respective specific assets. Just bear in mind that the default scene is contained in that folder, and as such, would have to be re-set if deleted.

* `flow_engine` contains all the "core" aspects of the engine: Sonic, rings, enemies, rails, etc. are all kept in there.



## Credits

* Sprites:
  
  * All assets originally made by Sonic Team, Dimps, and Sega.
  
  * Sprite rips:
    
    * Blazefirelp: Sonic Rush spring sprites
    
    * Ren "Foxx" Ramos: Sonic Advance 3 Sonic sprites
    
    * Chaofanatic: Boost effect, ring and ring sparkle effect from Sonic Rush Adventure

* iteachvader: Sonic Rush Soundfont

* Coderman64: original engine code

* c08oprkiua: Godot 4 port and overhaul
