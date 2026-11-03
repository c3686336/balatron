test:
    godot --headless --path . -s -d res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://test/unit -c -rd reports -rc 1

coverage gdcov="bin/gdcov-4.7-stable":
    mkdir -p coverage
    : > coverage/coverage.lcov
    xvfb-run --auto-servernum {{gdcov}} --path . --rendering-driver opengl3 --audio-driver Dummy -s -d --ignore-error-breaks res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://test/unit -c
    test -s coverage/coverage.lcov

cli seed="":
    godot --headless -s src/cli.gd -- {{seed}}

