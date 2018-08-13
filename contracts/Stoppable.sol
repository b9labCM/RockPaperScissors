pragma solidity ^0.4.18;

import "./Owned.sol";

contract Stoppable is Owned {
    bool isRunning;
    
    event LogPausedContract(address sender);
    event LogResumeContract(address sender);
    
    modifier onlyIfRunning {
        require(isRunning);
        _;
    }
    
    constructor() public {
        isRunning = true;
    }
    
    function pauseContract() public onlyOwner onlyIfRunning returns(bool success) {
        isRunning = false;
        emit LogPausedContract(msg.sender);
        return true;
    }
    
    function resumeContract() public onlyOwner onlyIfRunning returns(bool success) {
        require(!isRunning);
        isRunning = true;
        emit LogResumeContract(msg.sender);
        return true;
    }
}
