const RPS = artifacts.require("./RockPaperScissors.sol");

contract('RPS', function(accounts){
    let rps; 
    const owner = accounts[0]; 
    const account_A = accounts[1]; 
    const account_B = accounts[2];
    const account_C = accounts[3];
    let am;
    let pass1 = 'b';
    let pass2 = 'b';

    let passHashed = '0xb8a68323ff350f076062861482bede9ffafb1c8dab43874c9558ce36c0da7124';
  
    
    /* Deploy a new contract for each test */
    beforeEach(async function(){
        rps = await RPS.new({from: owner}); 
    });

    /*Test 1: Contract should be owned by the deployer*/
    it("Testing ownership", function() {
        return rps.owner({from: owner})
        .then(_owner => {
            let tmpOwner = _owner;
            assert.equal(tmpOwner, owner, "The deployer is not the owner!");
        })
    });

    /*Test 2: Join Game*/
    it("Testing joining game", function() {
        return rps.joinGame({from: account_A, value: web3.toWei(0.001, "ether")})
        .then(txObj => {
             assert.equal(txObj.receipt.status, 1, "Join fails ");
             assert.equal(txObj.logs.length,1, "event has not been emitted");
             assert.equal(txObj.logs[0].args._pa, account_A, "player address not set correctly")
        })

    });

    /*Test 3: Create Game*/
    it("Testing creation game", function() {
        return rps.joinGame({from: account_A, value: web3.toWei(0.001, "ether")})
        .then(txObj => {
             assert.equal(txObj.receipt.status, 1, "Join fails ");
             assert.equal(txObj.logs.length,1, "event has not been emitted");
             assert.equal(txObj.logs[0].args._pa, account_A, "player address not set correctly")
	     return rps.joinGame({from: account_B, value: web3.toWei(0.001, "ether")})
        }).then(txObj => {
             assert.equal(txObj.receipt.status, 1, "Join 2 fails ");
             assert.equal(txObj.logs.length,1, "event 2 has not been emitted");
             assert.equal(txObj.logs[0].args._pa, account_B, "player 2 address not set correctly")
	     return rps.createGame(account_A, account_B)
        }).then(txObj => {
		assert.equal(txObj.receipt.status, 1, "Creation fails ");
             	assert.equal(txObj.logs.length,1, "event creation has not been emitted");
	})

    });

	/*Test 4: Play Game*/
    it("Testing creation game", function() {
        return rps.joinGame({from: account_A, value: web3.toWei(0.001, "ether")})
        .then(txObj => {
             assert.equal(txObj.receipt.status, 1, "Join fails ");
             assert.equal(txObj.logs.length,1, "event has not been emitted");
             assert.equal(txObj.logs[0].args._pa, account_A, "player address not set correctly")
	     return rps.joinGame({from: account_B, value: web3.toWei(0.001, "ether")})
        }).then(txObj => {
             assert.equal(txObj.receipt.status, 1, "Join 2 fails ");
             assert.equal(txObj.logs.length,1, "event 2 has not been emitted");
             assert.equal(txObj.logs[0].args._pa, account_B, "player 2 address not set correctly")
	     return rps.createGame(account_A, account_B)
        }).then(txObj => {
		assert.equal(txObj.receipt.status, 1, "Creation fails ");
             	assert.equal(txObj.logs.length,1, "event creation has not been emitted");
		let id = txObj.logs[0].args._idGames.toNumber();
		am = txObj.logs[0].args._totalAmount.toString(10);
		console.log(id);
		return rps.play(id, {from: owner})
	}).then(txObj => {
		assert.equal(txObj.receipt.status, 1, "Creation fails ");
             	assert.equal(txObj.logs.length,1, "event creation has not been emitted");
		let winner = txObj.logs[0].args._winner; //indirizzo 
		let win = txObj.logs[0].args._win; //indirizzo
		return rps.players(winner)
	}).then(tmp => {
		
		assert.equal(tmp[2].toString(10), am, "The win amount is not correct" )
	})

    });

})
