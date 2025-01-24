-include .env

.PHONY: all test deploy

build :; forge build

test :; forge test

install :
	forge install foundry-rs/forge-std@v1.9.5 --no-commit && \
	forge install openzeppelin/openzeppelin-contracts@v5.2.0 --no-commit

deploy-sepolia :
	@forge script script/DeployNFTGame.s.sol:DeployNFTGame --rpc-url $(SEPOLIA_RPC_URL) --account $(SEPOLIA_ACCOUNT) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy-anvil :
	@forge script script/DeployNFTGame.s.sol:DeployNFTGame --rpc-url $(RPC_URL) --account $(ANVIL_ACCOUNT) --broadcast -vvvv --sender $(ANVIL_ACCOUNT_ADDRESS)

fund-account :
	cast send $(SEPOLIA_ACCOUNT_ADDRESS) --value 0.01ether --rpc-url $(RPC_URL) --account $(ANVIL_ACCOUNT)
