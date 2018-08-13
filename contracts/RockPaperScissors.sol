pragma solidity ^0.4.24;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol#v1.9.0";
//import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/lifecycle/Pausable.sol#v1.9.0";

contract RockPaperScissors is Ownable{
    
    
    struct Player {
        address addrPlayer;
        uint move; // 0: none, 1:rock, 2:paper, 3: RockPaperScissors
        uint amount;
        bool status;
        uint wins;
    }
    
    struct Game {
        uint id_games;
        Player player1;
        Player player2;
        uint total_amount;
        
        }
        
    mapping(uint=>Game) public games;
    mapping(address => Player) public players;
    mapping(address => uint) public balances;
    
    event LogPlayer(address _pa, uint move, uint amount, bool status );
    event LogGame(uint id_games, address _p1, address _p2, uint total_amount);
    event LogPlay(uint move1, uint move2, uint win, address winner);
    
    constructor() public {
        
    }
    
    function createGame(address _player1, address _player2) public payable returns(bool success) {
        require(_player2 != _player1);
        require (players[_player1].status == true);
        require(players[_player2].status == true);
        
        uint gameCount = 1;
        uint tmp_amount = players[_player1].amount + players[_player2].amount; //use add function would be better
        
        emit LogGame(gameCount, _player1, _player2, tmp_amount);
        
        games[gameCount] = Game(gameCount,players[_player1],players[_player2],tmp_amount);
        gameCount = gameCount+1;
        
        return true;
    }
        
    function joinGame() public payable returns(bool success){
        require(msg.value > 0, "Insufficient funds");
        require(msg.sender != address(0), " address must not be 0x0");
        
        balances[msg.sender] += msg.value;
        balances[this] += msg.value;
        
        players[msg.sender] = Player(msg.sender,0, msg.value, true,0);
        emit LogPlayer(msg.sender,0, msg.value, true);
        return true;
    }
    
    function play(uint id_games) public returns( address winner) {
        require(games[id_games].total_amount > 0);
        
        uint amount1 = games[id_games].player1.amount;
        uint amount2 = games[id_games].player2.amount;
        uint tmp_amount = games[id_games].total_amount;
        
        games[id_games].player1.move = randn(1,3);
        games[id_games].player2.move = randn2(1,3);
        uint move1 = games[id_games].player1.move;
        uint move2 = games[id_games].player2.move;
        address tmp_winner;
        uint winner_index= compare(move1,move2);
        if (winner_index == 1) {
            games[id_games].player1.wins +=1;
            players[games[id_games].player1.addrPlayer].wins += 1;
            //witdraw
            tmp_winner = games[id_games].player1.addrPlayer;
            withdraw(tmp_winner, tmp_amount);
        }
        else if(winner_index == 2) {
            games[id_games].player2.wins +=1;
            players[games[id_games].player2.addrPlayer].wins += 1;
            //witdraw
            tmp_winner = games[id_games].player2.addrPlayer;
           
            withdraw(tmp_winner, tmp_amount);
            
        } else {
            //pareggio rigioca
            tmp_winner = 0x0;
        }
        
        emit LogPlay(move1, move2, winner_index, tmp_winner);
        return tmp_winner;
    }
    
    function compare(uint move1, uint move2) internal pure returns (uint win) {
        if (move1 == move2) return 0;
        if ( (move1 == 1 && move2==2) || 
             (move1 == 2 && move2==3) ||
             (move1 == 3 && move2==1) ) return 1;
        if ( (move1 == 1 && move2==3) || 
             (move1 == 2 && move2==1) ||
             (move1 == 3 && move2==2) ) return 2;
         
    }
    
    function withdraw(address receiver, uint amount) public returns(bool success){
        require(amount>0);
        balances[receiver] += amount;
        receiver.transfer(amount);
        return true; 
    }
    
    
    function randn(uint from, uint to) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp)))%to +from;
    }
    
    function randn2(uint from, uint to) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty)))%to +from;
    }
    
    
    
    
    
    
}
