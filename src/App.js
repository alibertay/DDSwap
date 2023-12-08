import React, { useState } from 'react';
import './App.css';

function App() {
    const [buttonText, setButtonText] = useState("Connect Wallet");
    const [buttonAction, setButtonAction] = useState(() => connectWallet)

    function connectWallet() {
        setButtonText("Swap");
        setButtonAction(() => swap);
    }

    function swap() {
        alert("Swapped");
    }

    return (
        <div className="App">
            <div className="centered-div">
                <button onClick={buttonAction}>
                    <span className="button-text">{buttonText}</span>
                </button>
            </div>
        </div>
    );
}

export default App;
