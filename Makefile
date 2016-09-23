GBDK_BIN=./gbdk/bin
OBJ=./obj
SRC=./src

build:
	mkdir -p $(OBJ)
	$(GBDK_BIN)/gbdk-n-assemble.sh $(OBJ)/main.rel $(SRC)/main.s
	$(GBDK_BIN)/gbdk-n-link.sh $(OBJ)/main.rel -o $(OBJ)/main.ihx
	$(GBDK_BIN)/gbdk-n-make-rom.sh $(OBJ)/main.ihx ball.gb

clean:
	rm -rf $(OBJ)
	rm -f ball.gb
