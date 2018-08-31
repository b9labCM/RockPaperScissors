const RPS = artifacts.require("./RockPaperScissors.sol");

contract('RPS', function(accounts){
    
    let rps; 
    
    const owner = accounts[0]; 
    const account_A = accounts[1]; 
    const account_B = accounts[2];
    const account_C = accounts[3];
    let am;
    
    let password = '1234';
    let gameId = 1;
    let requiredAmount = 0.0005;
    let move1 = 1;
    let move2 = 2;
    let duration = 100000000;
    
    /* Deploy a new contract for each test */
    beforeEach(async function(){
        rps = await RPS.new({from: owner}); 
    });

    /*Test 1: Deposit */
    it("Testing deposit", function(){
        return rps.balances(account_A)
        .then(balanceA => {
            assert.strictEqual(balanceA.toString(10), '0');
            return rps.deposit({from: account_A, value: web3.toWei(0.001, "ether")})
        }).then( txObj => rps.balances(account_A)
        ).then(newBalanceA => {
            assert.strictEqual(newBalanceA.toString(10), web3.toWei(0.001, "ether").toString(10));
        })
    });

   

    /*Test 2: Create Game*/
    it("Testing creation game", function() {
        return rps.computeHash(password, move1)
        .then( hash1 => {
        return rps.createGame(gameId, requiredAmount, hash1, duration, {from: account_A})
        }).then( txObj => {
		    assert.equal(txObj.receipt.status, 1, "Creation fails ");
            assert.equal(txObj.logs.length,1, "Event creation has not been emitted");
	    })

    });

     /*Test 3: Join Game */
    it("Testing joining game", function() {
        return rps.deposit({from: account_A, value: web3.toWei(0.001, "ether")})
        .then( txObj => {
            return rps.computeHash(password, move1)
        }).then( hash1 => {
            return rps.createGame(gameId, requiredAmount, hash1, duration, {from: account_A})
        }).then(txObj => {
            return rps.deposit({from: account_B, value: web3.toWei(0.001, "ether")})
        }).then( txObj => {
            return rps.joinGame(gameId, move2, {from: account_B})
        }).then(txObj => {
             assert.equal(txObj.receipt.status, 1, "Join fails ");
             assert.equal(txObj.logs.length,1, "event has not been emitted");
             assert.equal(txObj.logs[0].args.player, account_B, "player address not set correctly")
        })

    });

    /*Test 4: Play Game*/
    it("Testing play game", function() {
        return rps.deposit({from: account_A, value: web3.toWei(0.001, "ether")})
        .then( txObj => {
            return rps.computeHash(password, move1)
        }).then( hash1 => {
            return rps.createGame(gameId, requiredAmount, hash1, duration, {from: account_A})
        }).then(txObj => {
            return rps.deposit({from: account_B, value: web3.toWei(0.001, "ether")})
        }).then( txObj => {
            return rps.joinGame(gameId, move2, {from: account_B})
        }).then(txObj => {
             return rps.playGame(gameId, password, move1, {from: account_A})
        }).then( txObj => {
            assert.equal(txObj.receipt.status, 1, "Play fails ");
            assert.equal(txObj.logs.length,1, "Event play has not been emitted");
            assert.equal(txObj.logs[0].args.winner, account_B);
        })
    });

    /*Test Withdraw*/
    
    
    /*Test Withdraw back*/

})
