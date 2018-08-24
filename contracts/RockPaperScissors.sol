pragma solidity ^0.4.24;
import "./Owned.sol";
import "./Stoppable.sol";


//import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/lifecycle/Pausable.sol#v1.9.0";

contract RockPaperScissors is Stoppable {
    uint gameCount = 1;
    
    struct Player {
        address addrPlayer;
        uint move; // 0: none, 1:rock, 2:paper, 3:Scissors
        uint balance;
        bool status;
        uint wins;
    }
    
    struct Game {
        uint idGames;
        Player player1;
        Player player2;
        uint totalAmount;
    }
        
    mapping(uint=>Game) public games;
    mapping(address => Player) public players;
    
    event LogPlayer(address _pa, uint move, uint balance,bool status, uint wins);
    event LogGame(uint _idGames, address _p1, address _p2, uint _totalAmount);
    event LogPlay(uint _move1, uint _move2, uint _win, address _winner);
    
    constructor () public { }
    
     function joinGame() public payable onlyIfRunning returns(bool success){
        require(msg.value > 0, "Insufficient funds");
        require(msg.sender != address(0), " address must not be 0x0");
        require(msg.sender != owner, " address must not be 0x0");
        
        emit LogPlayer(msg.sender,0, msg.value, true, 0);
        players[msg.sender] = Player(msg.sender,0, msg.value, true,0);
        return true;
    }
    
    function createGame(address _player1, address _player2) public onlyIfRunning returns(bool success) {
        require(_player2 != _player1, "The player must be different");
        require (players[_player1].status == true, "Player 1 must be enabled");
        require(players[_player2].status == true, "Player 2 must be enabled");
        
        uint tmpAmount = players[_player1].balance + (players[_player2].balance); //use add function would be better
        
        emit LogGame(gameCount, _player1, _player2, tmpAmount);
        
        games[gameCount] = Game(gameCount,players[_player1],players[_player2],tmpAmount);
        gameCount += 1;
        
        return true;
    }
        
    // for now moves are randomnly set XD  
    function play(uint idGames) public onlyIfRunning onlyOwner returns( address winner) {
        require(games[idGames].totalAmount > 0);
        
        
        uint tmpAmount = games[idGames].totalAmount;
        
        games[idGames].player1.move = randn(1,3);
        games[idGames].player2.move = randn2(1,3);
        uint move1 = games[idGames].player1.move;
        uint move2 = games[idGames].player2.move;
        
        address tmpWinner;
        uint winnerIndex = compare(move1,move2);
        
        if (winnerIndex == 1) {
            games[idGames].player1.wins +=1;
            
            //witdraw
            tmpWinner = games[idGames].player1.addrPlayer;
            withdraw(tmpWinner, tmpAmount);
        }
        else if(winnerIndex == 2) {
            games[idGames].player2.wins +=1;
            
            //witdraw
            tmpWinner = games[idGames].player2.addrPlayer;
            withdraw(tmpWinner, tmpAmount);
            
        } else {
            //pareggio rigioca
            tmpWinner = 0x0;
        }
        
        emit LogPlay(move1, move2, winnerIndex, tmpWinner);
        return tmpWinner;
    }
    
    function compare(uint move1, uint move2) internal pure returns (uint win) {
        if (move1 == move2) return 0;
        if ( (move1 == 1 && move2==2) || 
             (move1 == 3 && move2==2) ||
             (move1 == 3 && move2==1) ) return 2;
        if ( (move1 == 1 && move2==3) || 
             (move1 == 2 && move2==1) ||
             (move1 == 2 && move2==3) ) return 1;
         
    }
    
    function withdraw(address receiver, uint amount) internal onlyIfRunning returns(bool success){
        require(amount>0);
        // add require ....
        players[receiver].balance += amount;
        receiver.transfer(amount);
        return true; 
    }
    
    /*Utils*/
    
    function randn(uint from, uint to) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp)))%to +from;
    }
    
    function randn2(uint from, uint to) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty)))%to +from;
    }
    
    
}

