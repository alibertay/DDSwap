import React, { useState } from 'react';
import './App.css';
import changePNG from './change.png';


function App() {
    const [buttonText, setButtonText] = useState("Connect Wallet");
    const [buttonAction, setButtonAction] = useState(() => connectWallet)

    const [swapTextColor, setSwapTextColor] = useState("#D89F0A"); 
    const [liqTextColor, setLiqTextColor] = useState("#574A00");
    const [swapScreen, setSwapScreen] = useState(true);

    const [isWalletConnected, setIsWalletConnected] = useState(false);

    function connectWallet() {
        setIsWalletConnected(true);
        setButtonText("Swap")
        setButtonAction(() => swap);
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
