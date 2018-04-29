App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  balance: 0,
  instance: null,

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
