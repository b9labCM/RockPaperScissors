pragma solidity ^0.4.18;

contract Owned {
    address public owner;
    
    event LogChangeOwner(address sender, address newOwner);
    
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }
    
    function changeOwner(address newOwner) internal onlyOwner returns(bool success){
        owner = newOwner;
        emit LogChangeOwner(msg.sender, newOwner);
        return true;
        
    }
}
