EXE = SpaceInvaders.exe
PDB = SpaceInvaders.pdb

all: build run

build:
	odin build ./src -out:$(EXE) -debug

run:
	./$(EXE)

clean:
	rm -rf $(EXE) $(PDB)
