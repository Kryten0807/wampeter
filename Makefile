all: clean install test docs

install:
	@echo "************************"
	@echo "* INSTALL DEPENDENCIES *"
	@echo "************************"
	@npm install --python=/usr/bin/python2.7

build:
	@echo "************************"
	@echo "* BUILD LIBRARY         *"
	@echo "************************"
	@gulp

test:
	@echo "************************"
	@echo "* TEST LIBRARY         *"
	@echo "************************"
	@./node_modules/.bin/tape test/*.tape.js | faucet

docs:
	@echo "************************"
	@echo "* CREATE DOCUMENTATION *"
	@echo "************************"
	@./node_modules/.bin/jsdoc --recurse --private --destination ./doc lib/*.js README.md

github.io:
	@echo "************************"
	@echo "* CREATE DOCUMENTATION *"
	@echo "* FOR GITHUB.IO        *"
	@echo "************************"
	@./node_modules/.bin/jsdoc --recurse --destination ../Kryten0807.github.io/wampeter lib/*.js README.md

clean:
	@echo "************************"
	@echo "* CLEANUP DIRECTORY    *"
	@echo "************************"
	-@rm -rf ./node_modules
	-@rm -rf ./doc

tidy:
	@echo "***********************"
	@echo "* CLEANUP BUILT FILES *"
	@echo "***********************"
	-@rm -rf ./lib/*
	-@rm -rf ./test/*
	-@rm -rf ./tape/*

.PHONY: all install test docs
