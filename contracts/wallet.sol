pragma solidity ^0.8.9;

import '../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract Wallet is ReentrancyGuard{
    
    using SafeMath for uint256;

    address[] public owners;
    uint limit;
    

    struct Transfer {
        uint256 id;
        uint256 amount;
        address sender;
        address payable reciever;
        uint256 approvals;
        bool hasBeenSent;
        bytes10 ticker;
    }
   
    struct Tokens{
        bytes10 ticker;
        address tokenAdd;
    }

    Transfer[] transferRequests;

    event ApprovalRecieved( uint256 _id, uint256 _approvals, address _approver );
    event TransferRequestCreated( uint256 _id, uint256 _amount, address _initiator, address _receiver );
    event TransferApproved( uint256 _id );
    event TransferMade( uint256 _id, uint256 _amount, address _sender, address _reciever, bool _hasBeenSent, bytes10 _ticker);
    event FundsDeposited( uint256 _amount, address reciever, bytes10 _ticker );

    mapping(bytes10 => Tokens) public availableTokens;
    mapping(address => mapping(uint256 => bool))approvals;
    mapping(address => mapping(bytes10 => uint256))balance;


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
    
    

    function deposit()public payable onlyOwners{
        require(msg.value > 0, "you must enter an amount greater than 0");
        balance[msg.sender]["ETH"].add(msg.value);
        emit FundsDeposited(msg.value, msg.sender, "ETH");
    }

    function depositeToken(bytes10 _ticker, uint256 _amount) public payable onlyOwners{
        require(msg.value > 0, "you must enter an amount greater than 0");
        require(availableTokens[_ticker].tokenAdd != address(0), "Not a valid token");

        IERC20(availableTokens[_ticker].tokenAdd).transferFrom(msg.sender, address(this), _amount);
        balance[msg.sender][_ticker].add(_amount);

        emit FundsDeposited(_amount, msg.sender, _ticker);
        
    }
    
    function getBalance(bytes10 _ticker)public view returns(uint){
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

    

    function createTransfer(uint256 _amount, address payable _reciever, bytes10 _ticker) public onlyOwners{
        emit TransferRequestCreated(transferRequests.length, _amount, msg.sender, _reciever);
        
        Transfer memory t;

        t.id = transferRequests.length;
        t.amount = _amount;
        t.sender = msg.sender;
        t.reciever = _reciever;
        t.approvals = 0;
        t.hasBeenSent = false;
        t.ticker = _ticker;


         transferRequests.push(t);
           
    
        
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
    
    function removeOwner(address _ownerToRemove) public onlyOwners{
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

    function approve(bytes10 _ticker, uint256 _id) public onlyOwners {
       
        require (approvals[msg.sender][_id] == false, "You are not able to approve twice");
        require (transferRequests[_id].hasBeenSent == false, "You can't approve a sent transaction");

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
    function transferFunds(bytes10 _ticker, uint _id) private nonReentrant{ 
        
        address reciever = transferRequests[_id].reciever;
        uint amount = transferRequests[_id].amount;
        
        if(_ticker == "ETH"){
            (bool success, ) = reciever.call{value: amount}("");
            require(success, "Transfer Failed");
            
        }else{
            IERC20(availableTokens[_ticker].tokenAdd).transfer(reciever, amount);
            
        }
        emit TransferMade( _id, amount, msg.sender, reciever, true, _ticker);
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