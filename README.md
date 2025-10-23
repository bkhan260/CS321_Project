# CS321 Project System Overview

## Purpose
Create a match three game.

### Project Summary
This is a match three game focused on aquatic life, the user will be able to play through multiple levels and be able to randomly generate puzzles to solve.

## Architecture
- **Frontend:** Godot 4.5.2
- **Backend:** Godot 4.5.2 - GDscript & C#

# Features
- Play/Pause/Quit
  - Users can stop in the middle of the game, and resume at any time, user can also quit at any point in the game
- Board interactions
  - User is able to swap two tiles at a time
- Scoring mechanic
  - Scoring based on combo mechanic + number of matches
- Combo Mechanic
  - The number of Items matched multiplies the score of the tiles matched
- Restricted number of turns
  - User has a limited amount of turns before the game ends, if they are able to save the aquatic animals before the moves are over they win.
- Special FX
  - Visual effects
  - Audio effects
- Random Level generation
  - User is able to generate a level with a completely random tile placement
- Hint function
  - User can use a limited number of hints to find potential matches.
