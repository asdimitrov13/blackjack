pragma solidity ^0.4.22;

import "./usingOraclize.sol";

contract Blackjack is usingOraclize{

	

	uint8[] public deck;
	uint8[13] cardValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10];
	uint private bet;

	struct Game {
		address playerAddress;
		uint[] playerCards;
		uint[] dealerCards;
		uint8 playerPts;
		uint8 dealerPts;
		bool playerStand;
		uint8 playerAces;
		uint8 dealerAces;
		bool inProgress;
	}

	mapping(address => Game) public games;
	mapping(uint => address) drawRequests;
	mapping(uint => bool) drawIsForPlayer;


	event cardDrawn (
		address gameId,
		uint card,
		bool forPlayer
	);

	constructor() {
		oraclize_setProof(proofType_Ledger);
		bet = 1 ether;
		for (uint8 i = 0; i < 52; i++) {
			deck.push(i);
		}
    }

	function startGame() external payable {
		require(msg.value == 1 ether);
		require(!games[msg.sender].inProgress);
		games[msg.sender] = Game(msg.sender, new uint[](0), new uint[](0), 0, 0, false, 0, 0, true);
		drawCard(msg.sender, false); 
		drawCard(msg.sender, true); 
	}

	function drawCard(address _playerAddress, bool _drawIsForPlayer) private constant {
		uint drawId = uint(oraclize_query("WolframAlpha", "random number between 0 and 51"));
		drawRequests[drawId] = _playerAddress;
		drawIsForPlayer[drawId] = _drawIsForPlayer;
	}

	function stand() public {
		address _playerAddress = msg.sender;
		if (games[_playerAddress].dealerPts < 17) {
			drawCard(_playerAddress, false);
			//player wins
		} else if (games[_playerAddress].playerPts > games[_playerAddress].dealerPts) {
			resolveGame(_playerAddress, true, false);
			//dealer wins
		} else if (games[_playerAddress].playerPts < games[_playerAddress].dealerPts) {
			resolveGame(_playerAddress, false, false);
			//tie
		} else {
			resolveGame(_playerAddress, false, true);
		}
	}

	function hit() public {
		address _playerAddress = msg.sender;
		drawCard(_playerAddress, true);
		if (games[_playerAddress].dealerPts < 17) {
			drawCard(_playerAddress, false);
		}
	}

	function () external payable{
	}

	function resolveGame(address _playerAddress, bool playerWins, bool isDraw) private {

		if (playerWins) {
			_playerAddress.transfer(2 ether);
		} else if (isDraw) {
			_playerAddress.transfer(1 ether);
		}

		games[_playerAddress].inProgress = false;
	}

	function __callback(bytes32 _queryId, string _result, bytes _proof) public{
		if (msg.sender != oraclize_cbAddress()) {
			revert("Invalid caller, this function should be called only by Oraclize");
		}
        uint card = parseInt(_result);
        uint qId = uint(_queryId);

        address _playerAddress = drawRequests[qId];

        bool cardAlreadyDrawn = false;
        //check player cards
        for (uint i = 0; i < games[_playerAddress].playerCards.length; i++) {
        	if (card == games[_playerAddress].playerCards[i]) {
        		cardAlreadyDrawn = true;
        	}
        }
        //check dealer cards
        for (uint j = 0; j < games[_playerAddress].dealerCards.length; j++) {
        	if (card == games[_playerAddress].dealerCards[j]) {
        		cardAlreadyDrawn = true;
        	}
        }

        if (!cardAlreadyDrawn) {
	        if (drawIsForPlayer[qId]) {
	        	games[_playerAddress].playerCards.push(card);
	        	games[_playerAddress].playerPts += cardValues[card % 13];

	        	if (card % 13 == 0) {
	        		games[_playerAddress].playerAces++;
	        	}

	        	if (games[_playerAddress].playerPts > 21 && games[drawRequests[qId]].playerAces > 0) {
	        		games[_playerAddress].playerPts -= 10;
	        		games[_playerAddress].playerAces--;
	        	}

	        	emit cardDrawn(_playerAddress, card, true);

	        	if (games[_playerAddress].playerPts > 21) {
	        		resolveGame(_playerAddress, false, false);
	        	}
	        } else {
	        	games[_playerAddress].dealerCards.push(card);
	        	games[_playerAddress].dealerPts += cardValues[card % 13];

	        	if (card % 13 == 0) {
	        		games[_playerAddress].dealerAces++;
	        	}

	        	if (games[_playerAddress].dealerPts > 21 && games[_playerAddress].dealerAces > 0) {
	        		games[_playerAddress].dealerPts -= 10;
	        		games[_playerAddress].dealerAces--;
	        	}

	        	emit cardDrawn(_playerAddress, card, false);
	        	//if player stands dealer will draw until he goes over 17
	        	if (games[_playerAddress].playerStand && games[_playerAddress].dealerPts < 17) {
	        		drawCard(_playerAddress, drawIsForPlayer[qId]);
	        	}

	        	if (games[_playerAddress].dealerPts > 21) {
	        		resolveGame(_playerAddress, true, false);
	        	}
	        }
	    } else {
	    	drawCard(_playerAddress, drawIsForPlayer[qId]);
	    }
   }
}



//Blackjack.deployed().then(function(i){app = i})

//Blackjack.deployed().then(c => c.send(web3.toWei(1, "ether"), {from: web3.eth.accounts[1]}).then(tx => {console.log(tx.tx); tx.logs.length && console.log(tx.logs[0].event, tx.logs[0].args)}))

//Blackjack.deployed().then(c => {c.send(web3.toWei(5, "ether"), {from: web3.eth.accounts[0]}).then(tx => {}); app=c;})

//app.startGame({from:web3.eth.accounts[0], value: web3.toWei(1, "ether")});

//app.hit({from: web3.eth.accounts[0]})

//app.hit({from})

//web3.eth.getBalance(web3.eth.accounts[0])

//app.stand({from: web3.eth.accounts[0]})

//app.games(web3.eth.accounts[0])

