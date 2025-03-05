-include .env

.PHONY: all clean remove install update build test coverage snapshot format anvil deploy verify

all: clean remove install update build

# Clean the repo
clean :; forge clean

# Remove modules
remove:
	rm -f .gitmodules && \
	rm -rf .git/modules/* && \
	rm -rf lib && \
	touch .gitmodules

# Instal dependencies
install:
	forge install foundry-rs/forge-std@v1.9.6 --no-commit
	forge install OpenZeppelin/openzeppelin-contracts@v5.2.0 --no-commit

# Update dependencies
update :; forge update

# Build
build :; forge build

# Run tests
test :; forge test

# Estimate test coverage
coverage :; forge coverage

# Create gas snapshot
snapshot :; forge snapshot

# Format
format :; forge fmt

# Start local node
anvil :; anvil

# Deploy
deploy:
	forge script script/Deploy.s.sol:Deploy \
	--rpc-url $(RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--broadcast \
	--verify \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	-vvvv

# Verify contract
verify:
	forge verify-contract $(CONTRACT_ADDRESS) \
		$(CONTRACT_NAME) \
		--etherscan-api-key $(ETHERSCAN_API_KEY) \
		--chain $(CHAIN_ID) \
		--watch

