pragma solidity 0.8.7;

contract Wallet{

    address[] public owners;
    uint limit;

    struct Transfer {
        uint amount;
        address payable reciever;
        uint approvals;
        bool hasBeenSent;
        uint id;
    }

    Transfer[] transferRequests;

    event ApprovalRecieved(uint256 _id, uint256 _approvals, address _approver);
    event TransferRequestCreated(uint256 _id, uint256 _amount, address _initiator, address _receiver);
    event TransferApproved(uint256 _id);

    mapping(address => mapping(uint256 => bool))approvals;

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

    constructor(address[] memory _owners, uint256 _limit){
        owners = _owners;
        limit = _limit;
    }

    function deposit()public payable{}

    function createTransfer(uint256 _amount, address payable _receiver) public onlyOwners{
        emit TransferRequestCreated(transferRequests.length, _amount, msg.sender, _receiver);
        transferRequests.push(Transfer(_amount, _receiver, 0, false, transferRequests.length));
    }

    function approve(uint256 _id) public onlyOwners {
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
            transferRequests[_id].reciever.transfer(transferRequests[_id].amount);
            emit TransferApproved(_id);
        }
    }

    function getTransferRequests() public view returns(Transfer[] memory){
        return transferRequests;
    }

    

}