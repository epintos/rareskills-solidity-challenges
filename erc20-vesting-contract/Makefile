-include .env

.PHONY: all test deploy

build :; forge build

test :; forge test

install :
	forge install foundry-rs/forge-std@v1.9.5 --no-commit && \
	forge install openzeppelin/openzeppelin-contracts@v5.2.0 --no-commit
