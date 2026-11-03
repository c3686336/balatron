test:
    godot --headless -s addons/gut/gut_cmdln.gd -gexit

cli seed="":
    godot --headless -s src/cli.gd -- {{seed}}
