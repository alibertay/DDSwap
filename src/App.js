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

    const [fromToken, setFromToken] = useState('ETH');
    const [toToken, setToToken] = useState('ETH');
    const [amount, setAmount] = useState('');

    const DexABI = "";
    const DexContract = "";

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


    async function swap() {
        if (!isWalletConnected) {
            alert("Please connect your wallet first.");
            return;
        }

        // Ethers.js ile signer ve DEX kontratınızı tanımlayın
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();
        const dexContract = new ethers.Contract(DexContract, DexABI, signer);

        try {
            // ERC20 Token için approve işlemi
            if (ethers.utils.isAddress(fromToken) && fromToken !== 'ETH') {
                var TokenABI = "";
                const tokenContract = new ethers.Contract(fromToken, TokenABI, signer);
                await tokenContract.approve(DexContract, ethers.utils.parseEther(amount));
            }

            // Swap işlemleri
            if (fromToken === 'ETH' && ethers.utils.isAddress(toToken)) {
                // ETH'den Token'e swap
                await dexContract.swapEtherForToken(toToken, { value: ethers.utils.parseEther(amount) });
            } else if (ethers.utils.isAddress(fromToken) && toToken === 'ETH') {
                // Token'dan ETH'ye swap
                await dexContract.swapTokenForEther(fromToken, ethers.utils.parseEther(amount));
            } else if (ethers.utils.isAddress(fromToken) && ethers.utils.isAddress(toToken)) {
                // Token'dan Token'e swap
                await dexContract.swapTokenForToken(fromToken, ethers.utils.parseEther(amount), toToken);
            } else {
                alert("Invalid token selection.");
            }
        } catch (error) {
            console.error('Swap error:', error);
        }
    }


    async function addLiquidity() {
        if (!isWalletConnected) {
            alert("Please connect your wallet first.");
            return;
        }

        // TODO: Add them
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();

        const tokenAmount = 0;
        const tokenContractAddress = "TOKEN";
        var TokenABI = "";

        try {
            // Get approve
            const tokenContract = new ethers.Contract(tokenContractAddress, TokenABI, signer);
            await tokenContract.approve(DexContract, tokenAmount);

            // Contract interaction
            const dexContract = new ethers.Contract(DexContract, DexABI, signer);
            const ethersAmount = await dexContract.EthersAmount(tokenContractAddress);
            const liqAmounts = await dexContract.LiqAmounts(tokenContractAddress);
            const ethAmount = ethersAmount.mul(tokenAmount).div(liqAmounts);

            await dexContract.addLiq(tokenContractAddress, tokenAmount, { value: ethAmount });
        } catch (error) {
            console.error('Error adding liquidity:', error);
        }
    }


    async function removeLiquidity() {
        if (!isWalletConnected) {
            alert("Please connect your wallet first.");
            return;
        }

        // TODO: Add them
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        const signer = provider.getSigner();

        const tokenAmount = 0;
        const tokenContractAddress = "";

        try {
            // Remove Liq
            const dexContract = new ethers.Contract(DexContract, DexABI, signer);
            await dexContract.removeLiq(tokenContractAddress, tokenAmount);
        } catch (error) {
            console.error('Error removing liquidity:', error);
        }
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
            setButtonAction(() => addLiquidity);
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
                                value={amount}
                                onChange={e => setAmount(e.target.value)}
                            />

                            <select className="dropdown"
                                value={fromToken}
                                onChange={e => setFromToken(e.target.value)}>
                                <option value="0x7169D38820dfd117C3FA1f22a697dBA58d90BA06">USDT</option>
                                <option value="ETH">ETH</option>
                                <option value="0x779877A7B0D9E8603169DdbD7836e478b4624789">LINK</option>
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

                            <select className="dropdown"
                                value={toToken}
                                onChange={e => setToToken(e.target.value)}>
                                <option value="ETH">ETH</option>
                                <option value="0x7169D38820dfd117C3FA1f22a697dBA58d90BA06">USDT</option>
                                <option value="0x779877A7B0D9E8603169DdbD7836e478b4624789">LINK</option>
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
                                    <option value="0x7169D38820dfd117C3FA1f22a697dBA58d90BA06">USDT</option>
                                    <option value="ETH">ETH</option>
                                    <option value="0x779877A7B0D9E8603169DdbD7836e478b4624789">LINK</option>
                                </select>
                            </div>

                            {isWalletConnected ? (
                                <div>
                                    <button onClick={removeLiquidity} className="remove-liq-button">
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
