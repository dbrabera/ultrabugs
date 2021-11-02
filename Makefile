run:
	tic80 untitled.lua

load:
	tic80 --fs . --cmd "load untitled.lua"

build:
	mkdir -p .build
	tic80 --cli --fs . --cmd "load untitled.lua & export html .build/untitled & exit"

.PHONY: run load build