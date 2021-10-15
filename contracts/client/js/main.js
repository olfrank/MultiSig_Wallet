import data from '../../../build/contracts/Wallet.json';

Moralis.initialize("s8j9R2cqiJCrGskhbJHYK6xIeFszQizQjvOa2evd"); // Application id from moralis
Moralis.serverURL = "https://q0ird0onim8h.grandmoralis.com:2053/server"; //Server url from moralis

export async function loadWeb3() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum)
      await window.ethereum.enable()
    }
    else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider)
    }
    else {
      window.alert('Non-Ethereum browser detected. You should consider trying MetaMask!')
    }
  }