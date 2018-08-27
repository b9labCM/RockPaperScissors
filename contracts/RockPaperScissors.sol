pragma solidity ^0.4.24;

import "./Stoppable.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
contract RockPaperScissors is Stoppable {
    
    uint private gamePassword = 1234; 
    bytes32 private h1 = computeHash(1,gamePassword);
    bytes32 private h2 = computeHash(1,gamePassword);
    bytes32 private h3 = computeHash(1,gamePassword);
    
    struct Player {
        address addrPlayer;
        uint move; // 0:none, 1:rock, 2:paper, 3:Scissors
        bool status;
        bool inGame;
        uint wins;
        bytes32 secretHand;
    }
    
    struct Game {
        uint gameId;
        Player player1;
        Player player2;
        uint requiredAmount;
        uint gameBalance;
    }
        
    mapping(uint=>Game) public games;
    mapping(address => uint) public balances; 
    
    event LogDeposit(address sender, uint amount);
    event LogJoinGame(uint indexed gameId, address player);
    event LogGame(uint indexed gameId, uint amount);
    event LogPlay(uint move1, uint move2, uint win, address indexed winner);
    event LogExit(address sender, uint gameId);
    event LogWithdraw(address indexed sender, uint amount);
    
    constructor () public { }
    
    /* 0. Deposits funds to became a player */
    function deposit() public payable returns(bool success) {
        require(msg.value > 0, "Insufficient funds, please deposits something");
        require(msg.sender != address(0), "Address must not be 0x0");
        emit LogDeposit(msg.sender,  msg.value);
        balances[msg.sender] += msg.value; 
        return true;
    }
    
    /* 1. Create a game.*/
    function createGame(uint gameId, uint amount) public onlyIfRunning returns(bool success) {
        require(games[gameId].gameId == 0, "A game with this name already exist!");
        require(amount >= 0, "The amount has to be positive");
        
        Player memory p1 = Player({
                                    addrPlayer: address(0),
                                    move: 0,
                                    status: false,
                                    inGame: false,
                                    wins: 0,
                                    secretHand: ""
                                });
        Player memory p2 = Player({
                                    addrPlayer: address(0),
                                    move: 0,
                                    status: false,
                                    inGame: false,
                                    wins: 0,
                                    secretHand: ""
                                });
        
        emit LogGame(gameId, amount);
        games[gameId] = Game({ 
                                gameId: gameId,
                                player1: p1,
                                player2: p2,
                                requiredAmount: amount,
                                gameBalance: 0
                            });
        
        return true;
    }
    
    /* 1. Join an existing game. You have to deposit the right amount to join the game.*/
    function joinGame(uint gameId) public onlyIfRunning returns(bool success){
        require(games[gameId].gameId != 0, "This game does not exist");
        require(balances[msg.sender]  >= games[gameId].requiredAmount , "Insufficient funds to join this game!");
        require(msg.sender != address(0), " address must not be 0x0");
        require(msg.sender != owner, " address must not be the owner");
        require(games[gameId].player1.status == false || games[gameId].player2.status == false, "You can join only one game");
        
        emit LogJoinGame(gameId, msg.sender);
        
        // Enroll and enable players to play 
        if ( games[gameId].player1.status == false ){
            games[gameId].player1.status = true;
            games[gameId].player1.addrPlayer = msg.sender;
            
        } else if ( games[gameId].player2.status == false ) {
            require(games[gameId].player1.addrPlayer != msg.sender ); 
            games[gameId].player2.status = true;
            games[gameId].player2.addrPlayer = msg.sender;
            
        } else {
            revert();
        }
        
        //Update balances
        balances[msg.sender] -= games[gameId].requiredAmount;
        games[gameId].gameBalance += games[gameId].requiredAmount; 
        
        return true;
    }
    
    /* 3. Set a move before calling playGame function,
            or skip this and call playRandom function.
    */
    function playYourHand(uint gameId, bytes32 myHand) public onlyIfRunning returns( bool success ) {
        require(games[gameId].gameId != 0, "This game does not exist, check the ID");
        require(myHand != 0, "Make a move"); 
	    address tmpP1 = games[gameId].player1.addrPlayer;
	    address tmpP2 = games[gameId].player2.addrPlayer; 
        require(msg.sender == tmpP1 || msg.sender == tmpP2, "You have to join this game first!" );
        // Set the player's hand
	    if ( msg.sender == tmpP1 ){
        	games[gameId].player1.secretHand = myHand;
            games[gameId].player1.move = unveilHand(myHand);
	    } else if ( msg.sender == tmpP2 ){
        	games[gameId].player2.secretHand = myHand;
        	games[gameId].player2.move = unveilHand(myHand);
	    }   
        return true;
    }
    
    
    /* 4. Function to simulate a play game: hands are randomnly generated.*/  
    function playRandom(uint gameId) public onlyIfRunning onlyOwner returns( address winner) {
        require(games[gameId].gameId != 0, "This game does not exist, check the ID");
        require(games[gameId].gameBalance == games[gameId].requiredAmount*2, "Players have not deposited the right amount");
        
        uint tmpAmount = games[gameId].gameBalance;
        games[gameId].gameBalance = 0;
        
        games[gameId].player1.move = randn(1,3);
        games[gameId].player2.move = randn2(1,3);
        uint move1 = games[gameId].player1.move;
        uint move2 = games[gameId].player2.move;
        
        address tmpWinner;
        uint winnerIndex = compare(move1,move2);
        
        if (winnerIndex == 1) {
            games[gameId].player1.wins +=1;
            
            //witdraw
            tmpWinner = games[gameId].player1.addrPlayer;
            withdraw(tmpWinner, tmpAmount);
        }
        else if(winnerIndex == 2) {
            games[gameId].player2.wins +=1;
            
            //witdraw
            tmpWinner = games[gameId].player2.addrPlayer;
            withdraw(tmpWinner, tmpAmount);
            
        } else {
            //pareggio rigioca
            revert();
        }
        
        emit LogPlay(move1, move2, winnerIndex, tmpWinner);
        
        // Delete the game once it has been played
        delete games[gameId];
        
        return tmpWinner;
    }

    /* 5. Function to play the game: hands are previously set.*/
    function playGame(uint gameId) public onlyIfRunning onlyOwner returns( address winner) {
        require(games[gameId].gameId != 0, "This game does not exist, check the ID");
        require(games[gameId].gameBalance == SafeMath.mul(games[gameId].requiredAmount,2));
        
        uint tmpAmount = games[gameId].gameBalance;
        games[gameId].gameBalance= 0;
        
        uint move1 = games[gameId].player1.move;
        uint move2 = games[gameId].player2.move;
        
        address tmpWinner;
        uint winnerIndex = compare(move1,move2);
        
        if (winnerIndex == 1) {
            games[gameId].player1.wins +=1;
            
            //witdraw
            tmpWinner = games[gameId].player1.addrPlayer;
            balances[tmpWinner] += tmpAmount;
            withdraw(tmpWinner, tmpAmount);
        }
        else if(winnerIndex == 2) {
            games[gameId].player2.wins +=1;
            
            //witdraw
            tmpWinner = games[gameId].player2.addrPlayer;
            withdraw(tmpWinner, tmpAmount);
            
        } else {
            //pareggio rigioca
            tmpWinner = 0x0;
        }
        delete games[gameId];
        emit LogPlay(move1, move2, winnerIndex, tmpWinner);
        return tmpWinner;
    }
    
    /* In progress Function to play the game: hands are previously set.
    function playGameOnly(uint gameId) public onlyIfRunning onlyOwner returns( address winner) {
        require(games[gameId].gameId != 0, "This game does not exist, check the ID");
        require(games[gameId].gameBalance == SafeMath.mul(games[gameId].requiredAmount,2));
        
        uint tmpAmount = games[gameId].gameBalance;
        games[gameId].gameBalance= 0;
        
        uint move1 = games[gameId].player1.move;
        uint move2 = games[gameId].player2.move;
        
        address tmpWinner;
        uint winnerIndex = compare(move1,move2);
        
        if (winnerIndex == 1) {
            games[gameId].player1.wins +=1;
            tmpWinner = games[gameId].player1.addrPlayer;
        }
        else if(winnerIndex == 2) {
            games[gameId].player2.wins +=1;
            tmpWinner = games[gameId].player2.addrPlayer;
        } else {
            //pareggio rigioca
            revert();
        }
        balances[tmpWinner] += tmpAmount;
        emit LogPlay(move1, move2, winnerIndex, tmpWinner);
        return tmpWinner;
    } */
    
    /* Function to call to stop play --in progress --do not use it yet! 
       ...Searching a way to let players play many times in the same game.
       ...Call withdraw function only when a player exit the game
       ...Check if the player can leave the game 
    */
    function exitGame(uint gameId) public returns(bool success) {
        require(msg.sender == games[gameId].player1.addrPlayer || msg.sender == games[gameId].player2.addrPlayer);
        withdraw2();
        delete games[gameId];
        return true;
    }
    
    function withdraw(address receiver, uint amount) internal onlyIfRunning returns(bool success){
        require(amount>0);
        require(balances[receiver] > 0);
        require(amount <= balances[receiver]);
        emit LogWithdraw(msg.sender, amount);
        balances[receiver] = 0; 
        receiver.transfer(amount);
        return true; 
    }
    
    function withdraw2() internal onlyIfRunning returns(bool success){
        require(balances[msg.sender] > 0);
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        emit LogWithdraw(msg.sender, amount);
        msg.sender.transfer(amount);
        return true; 
    }
    
    /*Utils*/
    
    function randn(uint from, uint to) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp)))%to +from;
    }
    
    function randn2(uint from, uint to) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty)))%to +from;
    }
    
    function computeHash(uint password1, uint password2) public pure returns(bytes32){
        return keccak256(abi.encodePacked(password1,password2));
    }
    /* Map of hashed hands */
    function unveilHand(bytes32 hand) internal view onlyIfRunning returns (uint move){
        uint tmpHand;
        if (hand == h1){
            tmpHand = 1;
        } else if (hand == h2){
            tmpHand = 2;
        } else if (hand == h3){
            tmpHand = 3;
        }
        return tmpHand;
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
    
    
    
    
}


