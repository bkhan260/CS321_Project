# CS321 Project System Overview

## Purpose
Create a match three game.

### Project Summary
This is a match three game focused on aquatic life, the user will be able to play through multiple levels and be able to randomly generate puzzles to solve.

## Architecture
- **Frontend:** Godot 4.5.2
- **Backend:** Godot 4.5.2 - GDscript & C#

## Features
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

## Storyboard
[FigJam Board](https://www.figma.com/board/ZhOPx1p9xpauzA8R2RfQUr/Untitled?node-id=0-1&t=gYrX3un8fQwMBlkS-1)
![Storyboard Photo](https://github.com/bkhan260/CS321_Project/blob/main/StoryboardV0.png)

## Class Diagram / Blueprints
 For the MVP we used a few simple classes from the following:

 - LevelGenerator [LevelGenerator.gd](https://github.com/bkhan260/CS321_Project/blob/main/Scripts/level_generator.gd)
   - Generates a random layout of tiles when the game starts
   - Initializes all BoardItem objects with correct & valid data
 - BoardController [GameBoardScene.tscn](https://github.com/bkhan260/CS321_Project/blob/main/Scenes/GameBoardScene.tscn) <- Gd "Built-in" script: this means its stored in the scene file instead of its own individual file to save memory.
   - Controls user input & ouput
   - Controls UI elements such as the turn & score counters
   - Saves high score when user runs out of turns
     - This is saved across application runs
 - BoardItem [BoardItem.gd](https://github.com/bkhan260/CS321_Project/blob/main/Scripts/board_item.gd)
   - Data representation of an item on the board
   - Stores Positon & Item type data
   - Can be mutated durring runtime
 - MainMenu [MainMenuScene.tscn](https://github.com/bkhan260/CS321_Project/blob/main/Scenes/MainMenuScene.tscn) <- Another "built-in" script (To emphasise we wrote the code, its just 'built-in' to the scene file itself instead of its own seperate file)
     - File Loading to display the current high score (Persistent through multiple runs)
