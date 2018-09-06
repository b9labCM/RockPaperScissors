pragma solidity ^0.4.24;

import "./Stoppable.sol";


contract RockPaperScissors is Stoppable {

    enum Hand {NONE, ROCK, PAPER, SCISSORS}
    
    struct Game {
        address player1;
        address player2;
        
        uint requiredAmount;
        bytes32 secretHand1;
        //bytes32 secretHand2;
        Hand Hand2;

        uint expiringTime;

        uint balance; // not so useful maybe...
    }

    mapping (address => uint) public balances;
    mapping (uint  => Game) games;

    event LogDeposit(address sender, uint amount);
    event LogCreateGame(uint gameId, uint requiredAmount, bytes32 secretHand1);
    event LogJoinGame(uint gameId, address player);
    event LogPlay(Hand move1, Hand move2, address player1, address player2, address indexed winner, bytes32 secretHand1);
    event LogWithdraw(address indexed sender, uint amount);

    constructor () public {}

    /* 0. Deposits funds to became a player */
    function deposit() public payable returns(bool success){
        require(msg.value > 0, "Insufficient funds, please deposits something");
        require(msg.sender != address(0), "Address must not be 0x0");
        emit LogDeposit(msg.sender,  msg.value);
        balances[msg.sender] += msg.value; 
        return true;
    }
    /* 1. Create Game  */
    // to prevent the problem I can set the second player address here, so anyone except him can join this game. In this case there is no need to hash move2
    function createGame(uint _gameId, uint _requiredAmount, bytes32 _secretHand1, uint duration, address _player2) external onlyIfRunning returns(bool success){
        require(games[_gameId].player1 == address(0), "The game already exist!");
        require(balances[msg.sender] >= _requiredAmount, "Insufficient funds to join the game");
        require(msg.sender != _player2, "");
        emit LogCreateGame(_gameId,_requiredAmount, _secretHand1);
        uint _expiringTime = now + duration; //use safemath

        games[_gameId] = Game({ 
            player1: msg.sender,
            player2: _player2,
            requiredAmount: _requiredAmount,
            secretHand1: _secretHand1,
            Hand2: Hand.NONE,
            expiringTime: _expiringTime,
            balance: _requiredAmount
            });

        balances[msg.sender] -= _requiredAmount;
     
        return true;
    }

    /* 2. Join game: another player can join the game created */
    function joinGame(uint8 _gameId, Hand _move2) external  onlyIfRunning returns(bool success){
        require(now <= games[_gameId].expiringTime, "");
        require(games[_gameId].player1 != address(0), "");
        //require(msg.sender != games[_gameId].player1, "");
        require(msg.sender == games[_gameId].player2, "");
        require(balances[msg.sender] >= games[_gameId].requiredAmount, "");
        //require(_move2 != Hand.NONE, "You should play");

        balances[msg.sender] -= games[_gameId].requiredAmount;
		
        emit LogJoinGame(_gameId, msg.sender);

        //games[_gameId].player2 = msg.sender;
        //games[_gameId].secretHand2 = _secretHand2;
        games[_gameId].Hand2 = _move2;
        games[_gameId].balance += games[_gameId].requiredAmount;

        return true;
    }

    /* 3. Play game: compare the two hands and select a winner */
    function playGame (uint _gameId, uint _password1, Hand _move1) external onlyIfRunning 
    returns(address winnerAddr, bool success){
        require(now <= games[_gameId].expiringTime, "");
        require(_move1 != Hand.NONE, "You should choice");
        assert(games[_gameId].balance == games[_gameId].requiredAmount + games[_gameId].requiredAmount); // use safemath
		
        bytes32 hash1 = computeHash(_password1, _move1);
        require (hash1 == games[_gameId].secretHand1, "Player one has changed his move...");

        //bytes32 hash2 = computeHash(_password2, _move2);
        //require (hash2 == games[_gameId].secretHand2, "Player two has changed his move...");
		
        uint winner = compare(_move1, games[_gameId].Hand2);
        //uint winner = compare(_move1, _move2);

        if(winner == 1){
            balances[games[_gameId].player1] += 2*games[_gameId].requiredAmount;
            winnerAddr = games[_gameId].player1;
		}else if (winner == 2){
			balances[games[_gameId].player1] += 2*games[_gameId].requiredAmount;
			winnerAddr = games[_gameId].player2;
		}else{
			balances[games[_gameId].player1] += games[_gameId].requiredAmount;
			balances[games[_gameId].player2] += games[_gameId].requiredAmount;
			winnerAddr = address(0);
			success = false;	
		}
        emit LogPlay(_move1, games[_gameId].Hand2, games[_gameId].player1, games[_gameId].player2, winnerAddr, hash1);
        delete games[_gameId];
        success = true;
    }

	/* Withdraw */
    function withdraw() external returns(bool success){
        require(balances[msg.sender] > 0, "Nothing to withdraw...");
               
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        emit LogWithdraw(msg.sender, amount);
        msg.sender.transfer(amount);

        return true;
    }

    // Only arrange balances without transfer any amount. Use withdraw to do that
    function withdrawBack(uint _gameId) public returns(bool success){
        // You can take back money only if the session is expired
        require(now > games[_gameId].expiringTime, "ok...Session expired");
        require(games[_gameId].secretHand1 != 0x0, "");
        require(msg.sender == games[_gameId].player1 || msg.sender == games[_gameId].player2, "You are not a player of this game");
        //require(balances[msg.sender] > 0, "Nothing to withdraw...");
        // keep trace of withrawable amount
        uint withdrawableAmount = games[_gameId].balance;
        games[_gameId].balance = 0;

        // P1 create the game but nobody join the game within the deadline -> P1 takes back his money
        if (msg.sender == games[_gameId].player1 && games[_gameId].player2 == address(0)){
            balances[games[_gameId].player1] += withdrawableAmount;
        // P1 e P2 join the game but they do not play within the deadline -> P1 and P2 take back their money 
        } else if (msg.sender == games[_gameId].player2 ){
            balances[games[_gameId].player1] += withdrawableAmount/2;  //use safemath
            balances[games[_gameId].player2] += withdrawableAmount/2;
            // The remainder shoud be zero since players deposit the same amount to join the game 
        }
        
        return true;
    }

    /*UTILS*/ 
    //Helpers
    function computeHash(uint password, Hand move) public pure returns(bytes32){
        return keccak256(abi.encodePacked(password, move));
    }

    //1-rock ; 2-paper ; 3-scissors
    function compare(Hand move1, Hand move2) internal pure returns(uint win){
        if (move1 == move2) return 0;
        if ( (move1 == Hand.ROCK && move2==Hand.PAPER) || 
             (move1 == Hand.PAPER && move2==Hand.SCISSORS) ||
             (move1 == Hand.SCISSORS && move2==Hand.ROCK) ) return 2;
        if ( (move1 == Hand.ROCK && move2==Hand.SCISSORS) || 
             (move1 == Hand.PAPER && move2==Hand.ROCK) ||
             (move1 == Hand.SCISSORS && move2==Hand.PAPER) ) return 1;
    }



    
}


