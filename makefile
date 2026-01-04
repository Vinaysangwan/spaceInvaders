EXE = SpaceInvaders.exe

all: build run

build:
	odin build ./src -out:$(EXE) -debug

run:
	./$(EXE)