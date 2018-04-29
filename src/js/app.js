App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  balance: 0,
  instance: null,

  cardNames: ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'],
  cardSuits: ['&clubs;', '&diams;', '&hearts;', '&spades;'],
  cardsDrawn: [],

  init: function() {
    
    return App.initWeb3();
  },

  initWeb3: function() {
    if (typeof web3 !== 'undefined') {
      // If a web3 instance is already provided by Meta Mask.
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // Specify default instance if no web3 instance provided
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:8545');
      web3 = new Web3(App.web3Provider);
    }

    return App.initContract();
  },

  initContract: function() {
    $.getJSON("Blackjack.json", function(blackjack) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.Blackjack = TruffleContract(blackjack);
      // Connect provider to interact with contract
      App.contracts.Blackjack.setProvider(App.web3Provider);

      return App.render();
    });
  },

  listenForEvents: function() {
      App.instance.cardDrawn({}, {
        fromBlock: 'latest',
        toBlock: 'latest'
      }).watch(function(error, event) {

        if(!error) {
          var cardVal = event.args.card.c[0];

          if (App.cardsDrawn.indexOf(cardVal) === -1) {
            App.cardsDrawn.push(cardVal);
            var cardString = App.cardNames[cardVal % 13] + " " + App.cardSuits[Math.floor(cardVal / 13)] + " ";
            var cardSuit = Math.floor(cardVal / 13);
            if (event.args.forPlayer) {
              if (cardSuit === 2 || cardSuit === 3) {
                $("#playerCards").append(App.cardNames[cardVal % 13] + " <span style=\"color:red;\">" + App.cardSuits[cardSuit] + "</span> ");
              } else {
                $("#playerCards").append(App.cardNames[cardVal % 13] + " " + App.cardSuits[cardSuit]);
              }
            } else {
              if (cardSuit === 2 || cardSuit === 3) {
                $("#dealerCards").append(App.cardNames[cardVal % 13] + " <span style=\"color:red;\">" + App.cardSuits[cardSuit] + "</span> ");
              } else {
                $("#dealerCards").append(App.cardNames[cardVal % 13] + " " + App.cardSuits[cardSuit]);
              }
            }
          }
        }
      });
  },

  startGame: function() {
    App.instance.startGame({from: App.account, value: web3.toWei(1, "ether")});
  },

  hit: function() {
    App.instance.hit({from: App.account});
  },

  stand: function() {
    App.instance.stand({from: App.account});
  },

  render: function() {

    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);
      };
      web3.eth.getBalance(App.account, function(err, balance){
        $("#playerBalance").html("Your Balance: " + balance.c[0] / 10000 + " ether");
      });
    });

    // Load contract data
    App.contracts.Blackjack.deployed().then(function(_instance) {
      App.instance = _instance;
      App.listenForEvents();
      return App.instance;
    });

    $("#dealerCards").html("Dealer's cards: ");
    $("#playerCards").html("Your cards: ");

    $("#startGame").on("click", App.startGame);
    $("#hit").on("click", App.hit);
    $("#stand").on("click", App.stand);

  }

};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
