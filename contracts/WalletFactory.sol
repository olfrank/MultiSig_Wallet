pragma solidity 0.8.9;

contract WalletFactory {

    struct wallet{
        uint256 id; //wallet id
        address walletAdd;
        uint256 createdAt; //block.timestamp
        address walletCreator; 
    }

    wallet [] Wallets;

            
    mapping(address => mapping(uint256 => uint256)) walletBalance;


    function removeOwner(address walletAddress, address user) external {
        
    }

}