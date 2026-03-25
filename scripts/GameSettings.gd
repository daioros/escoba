# GameSettings.gd
# Autoload singleton to pass settings between scenes.
extends Node

var target_points:  int  = 21
var first_dealer:   int  = 1
var orientation:    int  = 0  # 0 = landscape, 1 = portrait
var sound_enabled:  bool = true
