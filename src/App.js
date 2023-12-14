import React, { useState } from 'react';
import './App.css';
import changePNG from './change.png';
import { ethers } from "ethers";


function App() {
    const [buttonText, setButtonText] = useState("Connect Wallet");
    const [buttonAction, setButtonAction] = useState(() => connectWallet)

    const [swapTextColor, setSwapTextColor] = useState("#D89F0A"); 
    const [liqTextColor, setLiqTextColor] = useState("#574A00");
    const [swapScreen, setSwapScreen] = useState(true);

    const [isWalletConnected, setIsWalletConnected] = useState(false);

    async function connectWallet() {
        if (typeof window.ethereum !== 'undefined') {
            try {
                await window.ethereum.request({ method: 'eth_requestAccounts' });

                const provider = new ethers.providers.Web3Provider(window.ethereum);

                addSepoliaNetwork();
                await provider.send("wallet_switchEthereumChain", [{ chainId: '0xaa36a7' }]); // Sepolia
                setIsWalletConnected(true);
                setButtonText("Swap")
                setButtonAction(() => swap);

                return provider;
            } catch (error) {
                console.error(error);
            }
        } else {
            console.log("Please install MetaMask!");
        }
    }

    async function addSepoliaNetwork() {
        try {
            await window.ethereum.request({
                method: 'wallet_addEthereumChain',
                params: [{
                    chainId: '0xaa36a7', 
                    rpcUrls: ['https://rpc.sepolia.org'], 
                    chainName: 'Sepolia Test Network',
                    nativeCurrency: {
                        name: 'Sepolia Ether',
                        symbol: 'ETH', 
                        decimals: 18
                    },
                    blockExplorerUrls: ['https://sepolia.etherscan.io/']
                }]
            });
        } catch (error) {
            console.error('Error adding Sepolia Network:', error);
        }
    }


    function swap() {
        alert("Swapped");
    }

    function addLiq() {
        alert("Liq added");
    }

    function removeLiq() {
        alert("Remove Liq");
    }

    function swapMenu() {
        setSwapTextColor("#D89F0A");
        setLiqTextColor("#574A00");

        setSwapScreen(true);

        if (isWalletConnected) {
            setButtonText("Swap");
            setButtonAction(() => swap);
        } else {
            setButtonText("Connect Wallet");
        }
     
    }

    function liqMenu() {
        setLiqTextColor("#D89F0A");
        setSwapTextColor("#574A00");

        setSwapScreen(false);

        if (isWalletConnected) {
            setButtonText("Add Liquidity");
            setButtonAction(() => addLiq);
        } else {
            setButtonText("Connect Wallet");
        }
        
    }

    function change() {
        alert("change");
    }

    return (
        <div className="App">
            <div className="centered-div">
                <span className="menu-text swap-text" style={{color: swapTextColor}} onClick={swapMenu}>Swap</span>
                <span className="menu-text liq-text" style={{ color: liqTextColor }} onClick={liqMenu}>Liquidity</span>
                {swapScreen ? (
                    <div>

                        <div className="input-container from-input-container">
                            <input
                                type="text"
                                placeholder="0.0"
                            />

                            <select className="dropdown">
                                <option value="">USDT</option>
                                <option value="option1">ETH</option>
                                <option value="option2">LINK</option>
                            </select>
                        </div>

                        <button onClick={change} className="change-button">
                            <img src={changePNG} alt="Change Button" />
                        </button>

                        <div className="input-container to-input-container">
                            <input
                                type="text"
                                placeholder="0.0"
                            />

                            <select className="dropdown">
                                <option value="">ETH</option>
                                <option value="option1">USDT</option>
                                <option value="option2">LINK</option>
                            </select>
                        </div>

                        <button onClick={buttonAction} className="swap-button">
                        <span className="button-text">{buttonText}</span>
                        </button>
                    </div>
                ) : (
                        <div>
                            <div className="input-container from-input-container">
                                <input
                                    type="text"
                                    placeholder="0.0"
                                />

                                <select className="dropdown">
                                    <option value="">USDT</option>
                                    <option value="option1">ETH</option>
                                    <option value="option2">LINK</option>
                                </select>
                            </div>

                            {isWalletConnected ? (
                                <div>
                                <button onClick={removeLiq} className="remove-liq-button">
                                    <span className="button-text">Remove Liquidity</span>
                                </button>

                                <button onClick={buttonAction} className="add-liq-button">
                                        <span className="button-text">{buttonText}</span>
                                    </button>
                                </div>
                            ) : 
                        
                                ( <div>
                                    <button onClick={buttonAction} className="add-liq-button" style={{marginTop: '15vh'}}>
                                        <span className="button-text">{buttonText}</span>
                                    </button>
                                    </div>
                                )}

                     
                    </div>
                )}
            </div>
        </div>
    );
}

export default App;
