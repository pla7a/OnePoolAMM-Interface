import React, { useEffect, useState } from "react";
import './App.css';
import { ethers } from "ethers";
import abi1 from './utils/Euler.json';
import abi2 from './utils/Gauss.json'

const App = () => {
  const [currentAccount, setCurrentAccount] = useState("");

  const contract1Address = "0x721E3CF153A80Bcc2367D15CaDC9b45ee2674C30";
  const contract1ABI = abi1.abi; 

  const contract2Address = "0xD2F68e36CE2Cb3328BACba792852d6d31AD7F0E1";
  const contract2ABI = abi2.abi;
  
  const checkIfWalletIsConnected = async () => {
    try {
      const { ethereum } = window;

      if (!ethereum) {
        console.log("Make sure you have metamask!");
        return;
      } else {
        console.log("We have the ethereum object", ethereum);
      }

      const accounts = await ethereum.request({ method: 'eth_accounts' });

      if (accounts.length !== 0) {
        const account = accounts[0];
        console.log("Found an authorized account:", account);
        setCurrentAccount(account);
      } else {
        console.log("No authorized account found")
      }
    } catch (error) {
      console.log(error);
    }
  }

  useEffect(() => {
    checkIfWalletIsConnected();
  }, [])

  const connectWallet = async () => {
    try {
      const { ethereum } = window;

      if (!ethereum) {
        alert("Get MetaMask!");
        return;
      }

      const accounts = await ethereum.request({ method: "eth_requestAccounts" });

      console.log("Connected", accounts[0]);
      setCurrentAccount(accounts[0]); 
    } catch (error) {
      console.log(error)
    }
  }

  const receiveT1 = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const c1 = new ethers.Contract(contract1Address, contract1ABI, signer);

        const receiveTxn = await c1.get_coins((0.5 * 10**18).toString());
        console.log("Mining...", receiveTxn.hash);

        await receiveTxn.wait();
      } else {
        console.log("Ethereum object doesn't exist!");
      }
    } catch (error) {
      console.log(error)
    }
  }

  const receiveT2 = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const c2 = new ethers.Contract(contract2Address, contract2ABI, signer);

        const receiveTxn = await c2.get_coins((0.5 * 10**18).toString());
        console.log("Mining...", receiveTxn.hash);

        await receiveTxn.wait();
      } else {
        console.log("Ethereum object doesn't exist!");
      }
    } catch (error) {
      console.log(error)
    }
  }

  const addEuler = async () => {
    try {
  // wasAdded is a boolean. Like any RPC method, an error may be thrown.
      let add1 = await ethereum.request({
        method: 'wallet_watchAsset',
        params: {
          type: 'ERC20', // Initially only supports ERC20, but eventually more!
          options: {
            address: contract1Address, // The address that the token is at.
            symbol: "Euler", // A ticker symbol or shorthand, up to 5 chars.
            decimals: 18, // The number of decimals in the token
            image: "https://todayinsci.com/E/Euler_Leonhard/EulerLeonhard300px.jpg", // A string url of the token logo
          }
        }
      })
    }
    catch (error) {
      console.log("error");
    }
  }

  const addGauss = async () => {
      try {
    // wasAdded is a boolean. Like any RPC method, an error may be thrown.
        let add2 = await ethereum.request({
        method: 'wallet_watchAsset',
        params: {
          type: 'ERC20', // Initially only supports ERC20, but eventually more!
          options: {
            address: contract2Address, // The address that the token is at.
            symbol: "Gauss", // A ticker symbol or shorthand, up to 5 chars.
            decimals: 18, // The number of decimals in the token
            image: "https://upload.wikimedia.org/wikipedia/commons/9/9b/Carl_Friedrich_Gauss.jpg", // A string url of the token logo
          }
        }
      })
      }
      catch (error) {
        console.log("error");
      }
    }
  
  return (
    
    <div className="mainContainer">
    {currentAccount && (<div className="topRight">
      <div class="left-cell">
        <h6>Not added tokens to wallet yet?</h6>
      </div>
      <div class="right-cell">
        <button className="addButton1" onClick={addEuler}>
          Add Euler
        </button>
        <button className="addButton1" onClick={addGauss}>Add Gauss</button>
      </div>
    </div>)}
      
      <div className="dataContainer">
        <div className="header">
        👋 Hey there!
        </div>

        <div className="bio">
        Why not take some free tokens?
        </div>

        {!currentAccount && (<button className="waveButton" onClick={connectWallet}>
          Connect your wallet
        </button>)}

        {currentAccount && (<button className="waveButton" onClick={receiveT1}>
          Claim free Euler Tokens
        </button>)}

        {currentAccount && (<button className="waveButton" onClick={receiveT2}>
          Claim free Gauss Tokens
        </button>)}

      </div>
    </div>
  );
}

export default App
