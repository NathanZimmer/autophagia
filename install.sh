#!/bin/bash
# Install script for TrenchBroom. You'll need to run the game config generators yourself.
# Namely: func_godot_fgd.tres, func_godot_logal_config.tres, func_godot_tb_game_config.tres
cd "$(dirname "$0")"
mkdir trench_broom

# Update this if you want the latest version of TrenchBroom... or just go download it yourself at that point
curl -L -o trench_broom/temp_trench_broom_install.7z https://github.com/TrenchBroom/TrenchBroom/releases/latest/download/TrenchBroom-Win64-v2024.1-Release.7z;
7z x -otrench_broom trench_broom/temp_trench_broom_install.7z;
rm trench_broom/temp_trench_broom_install.7z;

# Have Godot ignore this folder
touch trench_broom/.gdignore

cd -