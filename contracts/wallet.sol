pragma solidity ^0.8.9;

import '../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Wallet{
    
    using SafeMath for uint256;

    address[] public owners;
    uint limit;
    

    struct Transfer {
        uint256 amount;
        address payable reciever;
        address sender;
        uint256 approvals;
        bool hasBeenSent;
        uint256 id;
        string ticker;
    }
    
    struct Tokens{
        string ticker;
        address tokenAdd;
    }

    Transfer[] transferRequests;

    event ApprovalRecieved( uint256 _id, uint256 _approvals, address _approver );
    event TransferRequestCreated( uint256 _id, uint256 _amount, address _initiator, address _receiver );
    event TransferApproved( uint256 _id );

    mapping(string => Tokens) public availableTokens;
    mapping(address => mapping(uint256 => bool))approvals;
    mapping(address => mapping(string => uint256))balance;


    modifier onlyOwners(){
        bool owner = false;
        for(uint256 i = 0; i < owners.length; i++){
            if(owners[i]== msg.sender){
                owner = true;
            }
        }
        require (owner = true);
        _;
    }
    
    

    constructor(address[] memory _owners){
        owners = _owners;
        limit = calculateLimit(owners.length);
        // tokenList.push("ETH");
        
    }
    
    

    function deposit()public payable{
        require(msg.value > 0, "you must enter an amount greater than 0");
        balance[msg.sender]["ETH"].add(msg.value);
        
    }
    
    function getBalance(string memory _ticker)public view returns(uint){
        return balance[msg.sender][_ticker];
    }
    
    //75% of wallet owners must approve
    function calculateLimit(uint numOfAdd) public returns(uint){
        uint _limit = numOfAdd *75 / 100;
        limit = _limit;
        return limit;
    }
    function getLimit() public view returns(uint){
        return limit;
    }

    

    function createTransfer(uint256 _amount, address payable _receiver, string memory _ticker) public onlyOwners{
        
        emit TransferRequestCreated(transferRequests.length, _amount, msg.sender, _receiver);
        
        transferRequests.push(
            Transfer(_amount, _receiver, msg.sender, 0, false, transferRequests.length, _ticker)
            );
    }
    
    function addOwner(address _newOwner) public onlyOwners{
      
        for(uint i=0; i< owners.length +1; i++){
            if(owners[i] == _newOwner){
                revert("user is already an owner");
            }else{
                owners.push(_newOwner);
            }
        }
        
        calculateLimit(owners.length);
    }
    
    function removeOwner(address _ownerToRemove) public {
        uint userIndex;
        
        for(uint i = 0; i <= owners.length+1; i++){
            if(owners[i] == _ownerToRemove){
                userIndex == i;
                require(owners[i]== _ownerToRemove, "the owner doesnt exist");
            }
        }
        
        owners[userIndex] = owners[owners.length - 1];
        owners.pop();
        
        calculateLimit(owners.length);
        
    }

    function approve(string memory _ticker, uint256 _id) public onlyOwners {
        //owner should not be able to approve twice;
        require (approvals[msg.sender][_id] == false);
        //owner should not be able to approve a tx that has already been sent;
        require (transferRequests[_id].hasBeenSent == false);

        emit ApprovalRecieved(_id, transferRequests[_id].approvals, msg.sender);

        approvals[msg.sender][_id] == true;
        transferRequests[_id].approvals++;
        //condition
        if(transferRequests[_id].approvals >= limit){
            transferRequests[_id].hasBeenSent = true;
            transferFunds(_ticker, _id);
            // transferRequests[_id].reciever.transfer(transferRequests[_id].amount);
            emit TransferApproved(_id);
        }
    }
    
    //  call() is more gas efficient 
    function transferFunds(string memory _ticker, uint _id) public {
        
        address reciever = transferRequests[_id].reciever;
        uint amount = transferRequests[_id].amount;
        
        if(keccak256(bytes(_ticker)) == keccak256(bytes("ETH"))){
            
            (bool success, ) = reciever.call{value: amount}("");
            require(success, "Transfer Failed");
            
        }else{
            IERC20(availableTokens[_ticker].tokenAdd).transfer(reciever, amount);
            
        }
        
        //update balance
        balance[reciever][_ticker].add(amount);
        
        //update transferRequest array 
        transferRequests[_id] = transferRequests[transferRequests.length -1];
        transferRequests.pop();
        
    }

    function getTransferRequests() public view returns(Transfer[] memory){
        return transferRequests;
    }

}