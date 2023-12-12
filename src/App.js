import React, { useState } from 'react';
import './App.css';

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

    return (
        <div className="App">
            <div className="centered-div">
                <span className="menu-text swap-text" style={{color: swapTextColor}} onClick={swapMenu}>Swap</span>
                <span className="menu-text liq-text" style={{ color: liqTextColor }} onClick={liqMenu}>Liquidity</span>
                {swapScreen ? (
                    <button onClick={buttonAction}>
                    <span className="button-text">{buttonText}</span>
                    </button>
                ) : (
                        <button onClick={buttonAction}>
                            <span className="button-text">{buttonText}</span>
                        </button>
                )}
            </div>
        </div>
    );
}

export default App;
