pragma solidity 0.8.9;

contract WalletFactory {

    struct wallet{
        uint256 id;
        address walletAdd;
        uint256 createdAt;
        address walletCreator;
        
    }

    wallet [] Wallets;
}