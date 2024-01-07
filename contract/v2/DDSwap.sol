// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IToken {
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool); 
}

// TODO: token for stake
// TODO: stake function
// TODO: unstake function
// TODO: time limit for sepPools
// TODO: sepPools for token2token

contract DDSwap {

    // Vars
    uint256 CommisionRatio = 1;
    address owner;
    bool private locked;

    // Mappings
    mapping(address => uint256) LiqAmounts; // TokenLiq
    mapping(address => uint256) EtherAmounts; // EtherLiq for token

    mapping(address => mapping(address => uint256)) TokenLPs; // for LPs tokens
    mapping(address => mapping(address => uint256)) EtherLPs; // for LPs ethers
    mapping(address => address[]) LPList; // For pools LP list

    mapping(address => mapping(address => uint256)) LPsTotalFee; // LPsTotalFee

    mapping(address => uint256) LPsPoolCount; // To see how many pools are there for 1 LP

    // Experimental
    mapping(address => mapping(address => mapping(uint256 => uint256))) SepEtherToTokenPool;
    mapping(address => mapping(address => mapping(uint256 => uint256))) SepTokenToEtherPool;

    // Events
    event LiqAdd(address _LPAddress, address _tokenAddress, uint256 _tokenAmount, uint256 _etherAmount);
    event LiqRemove(address _LPAddress, address _tokenAddress, uint256 _tokenAmount, uint256 _etherAmount);
    event SwapEtherForToken(address _user, address _tokenAddress, uint256 _tokenAmount, uint256 _etherAmount);
    event SwapTokenForEther(address _user, address _tokenAddress, uint256 _tokenAmount, uint256 _etherAmount);
    event AddedToFeePool(address _tokenAddress, uint256 _tokenAmount);
    event FeeTaken(address _user, address _tokenAddress, uint256 _tokenAmount);

    constructor() {
        owner = msg.sender;
    }

    // Modifier to prevent reentrancy
    modifier noReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    // Only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "This is an only owner function");
        _;
    }

    function addLiq(address _tokenAddress, uint256 _tokenAmount) public payable noReentrant {

        if (EtherAmounts[_tokenAddress] > 0) {
            // I don't price check because I'm just trying to keep the rate the same.
            uint256 tokenPrice = EtherAmounts[_tokenAddress] / LiqAmounts[_tokenAddress];
            require(msg.value == tokenPrice * _tokenAmount);
        
        } else {
        
            // Can't create pool with 0 ether
            require(msg.value > 0); 
        
        }

        // get token
        IToken token = IToken(_tokenAddress);
        bool isTransfered = token.transferFrom(msg.sender, address(this), _tokenAmount);

        require(isTransfered);
        
        // increase pools
        LiqAmounts[_tokenAddress] += _tokenAmount;
        EtherAmounts[_tokenAddress] += msg.value;

        // add to lp list
        if (TokenLPs[msg.sender][_tokenAddress] == 0) {
            LPList[_tokenAddress].push(msg.sender);
            
            if(LPsPoolCount[msg.sender] == 0) {
                LPList[address(0x0)].push(msg.sender);
            }

            LPsPoolCount[msg.sender] += 1;
        }

        // add to lps
        TokenLPs[msg.sender][_tokenAddress] += _tokenAmount;
        EtherLPs[msg.sender][_tokenAddress] += msg.value;

        emit LiqAdd(msg.sender, _tokenAddress, _tokenAmount, msg.value);
    }

    function removeLiq(address _tokenAddress, uint256 _tokenAmount) public noReentrant {
        // Check if the liquidity provider has that many tokens in the pool.
        require(TokenLPs[msg.sender][_tokenAddress] >= _tokenAmount);

        // send token
        IToken token = IToken(_tokenAddress);
        bool isTransfered = token.transfer(msg.sender, _tokenAmount);

        require(isTransfered);

        // send ether
        uint256 getEtherAmount = (EtherAmounts[_tokenAddress] / LiqAmounts[_tokenAddress]) * _tokenAmount;
        payable(msg.sender).transfer(getEtherAmount);

        // decrease pools
        LiqAmounts[_tokenAddress] -= _tokenAmount;
        EtherAmounts[_tokenAddress] -= getEtherAmount;

        // decrease lps
        TokenLPs[msg.sender][_tokenAddress] -= _tokenAmount;
        EtherLPs[msg.sender][_tokenAddress] -= getEtherAmount;

        // remove from LP list?
        if (TokenLPs[msg.sender][_tokenAddress] == 0) {
            removeAddress(_tokenAddress, msg.sender);

            LPsPoolCount[msg.sender] -= 1;

            if (LPsPoolCount[msg.sender] == 0) {
                removeAddress(address(0x0), msg.sender);
            }
        }

        emit LiqRemove(msg.sender, _tokenAddress, _tokenAmount, getEtherAmount);
    }

    function getTokenForTokenPrice(address _token1Address, uint256 _token1Amount, address _token2Address) public view returns(uint256) {
        // Token 1 is sold, Token 2 is purchased

        // How much eth is Token1 worth?
        uint256 recievedEtherFromToken1 = getEtherForTokenPrice(_token1Address, _token1Amount);

        // How many eth can you buy from Token2 with this much eth?
        uint256 receivedToken2 = getTokenForEtherPrice(_token2Address, recievedEtherFromToken1);
    
        // Ratio the two together
        return receivedToken2 / _token1Amount; 
    }

    function getEtherForTokenPrice(address _tokenAddress, uint256 _tokenAmount) public view returns(uint256) {
        // Give tokens and get eth
        
        uint256 newTokenSupply = LiqAmounts[_tokenAddress] + _tokenAmount;
        uint256 newEtherSupply = EtherAmounts[_tokenAddress] * LiqAmounts[_tokenAddress] / newTokenSupply;
        uint256 receivedEther = EtherAmounts[_tokenAddress] - newEtherSupply;

        return receivedEther; 
    }

    function getTokenForEtherPrice(address _tokenAddress, uint256 _etherAmount) public view returns(uint256) {
        // Give ether and get tokens

        uint256 newEtherSupply = EtherAmounts[_tokenAddress] + _etherAmount;
        uint256 newTokenSupply = EtherAmounts[_tokenAddress] * LiqAmounts[_tokenAddress] / newEtherSupply;
        uint256 receivedToken = LiqAmounts[_tokenAddress] - newTokenSupply;

        return receivedToken;
    }

    function sepEtherForToken(address _tokenAddress) internal {
        // Give ether and get tokens

        // TODO: transfer and stake a token first
        
        // calculate commision
        uint256 commision = (msg.value * (CommisionRatio / 100));
        uint256 userPayEther = msg.value - commision;

        // Token Amount
        // calculate getTokenAmount
        uint256 getTokenAmount = getTokenForEtherPrice(_tokenAddress, userPayEther);

        // create SepPool for user and token
        SepEtherToTokenPool[msg.sender][_tokenAddress][getTokenAmount] = msg.value;
        
        // sep pool created, remove liq from main pools
        LiqAmounts[_tokenAddress] -= getTokenAmount;
        EtherAmounts[_tokenAddress] -= userPayEther;
    }

    function sepSwapEtherForToken(address _tokenAddress, uint256 _getTokenAmount) public payable {
        // User first have to sep liq and ether amount must be equal it
        uint256 userPayEther = SepEtherToTokenPool[msg.sender][_tokenAddress][_getTokenAmount];
        require(msg.value == userPayEther);

        // delete sep pool
        delete SepEtherToTokenPool[msg.sender][_tokenAddress][_getTokenAmount];

        // add ether to main pool
        EtherAmounts[_tokenAddress] += userPayEther;
        
        // give back staked tokens

        // give token to user
        IToken token = IToken(_tokenAddress);
        token.transfer(msg.sender, _getTokenAmount);
    }

    function swapEtherForToken(address _tokenAddress) public payable noReentrant {
        // Give ether and get tokens

        // ether cant be 0
        require(msg.value > 0);

        // It is important to do this without calculating the amount of tokens.
        // In this way, the balance of the pool is not disturbed.

        uint256 commision = (msg.value * (CommisionRatio / 100));
        uint256 userPayEther = msg.value - commision;

        // calculate getTokenAmount
        uint256 getTokenAmount = getTokenForEtherPrice(_tokenAddress, userPayEther);
        
        // increase ether pool for token
        EtherAmounts[_tokenAddress] += userPayEther;

        // increase LPs Ether
        increaseLPEtherPool(_tokenAddress, userPayEther);

        // transfer token
        IToken token = IToken(_tokenAddress);
        token.transfer(msg.sender, getTokenAmount);

        // decrease token pool
        LiqAmounts[_tokenAddress] -= getTokenAmount;

        // decrease LPs token
        decreaseLPTokenPool(_tokenAddress, getTokenAmount);

        // Add LP fee sender?
        // In LP pools address(0x0) represents ether
        addToFeePool(address(0x0), commision);

        emit SwapEtherForToken(msg.sender, _tokenAddress, getTokenAmount, userPayEther);
    }

     function sepTokenForEther(address _tokenAddress, uint256 _tokenAmount) internal {
        // Give token and get ether

        // TODO: transfer and stake a token first
        
        // calculate commision
        uint256 commision = (_tokenAmount * (CommisionRatio / 100));
        _tokenAmount = _tokenAmount - commision;

        // calculate etherAmount
        uint256 getEtherAmount = getEtherForTokenPrice(_tokenAddress, _tokenAmount);

        // create SepPool for user and token
        SepTokenToEtherPool[msg.sender][_tokenAddress][getEtherAmount] = _tokenAmount;
        
        // sep pool created, remove liq from main pools
        LiqAmounts[_tokenAddress] -= _tokenAmount;
        EtherAmounts[_tokenAddress] -= getEtherAmount;
    }

    function sepSwapTokenForEther(address _tokenAddress, uint256 _getEtherAmount) public payable {
        // User first have to sep liq and ether amount must be equal it
        uint256 userPayToken = SepTokenToEtherPool[msg.sender][_tokenAddress][_getEtherAmount];
        
        // take token from user
        IToken token = IToken(_tokenAddress);
        token.transferFrom(msg.sender, address(this), userPayToken);

        // delete sep pool
        delete SepEtherToTokenPool[msg.sender][_tokenAddress][_getEtherAmount];

        // add token to main pool
        LiqAmounts[_tokenAddress] += userPayToken;
        
        // give back staked tokens

        // give ether to user
        payable(msg.sender).transfer(_getEtherAmount);
    }

    function swapTokenForEther(address _tokenAddress, uint256 _tokenAmount) public noReentrant {
        // Give token and get ether

        // token amount cant be 0
        require(_tokenAmount > 0);

        // calculate commision and decrease from total token
        uint256 commision = (_tokenAmount * (CommisionRatio / 100));
        _tokenAmount = _tokenAmount - commision;

        // It is important to do this before the amount of ether is calculated.
        // In this way, the balance of the pool is not disrupted.

        // calculate getEtherAmount
        uint256 getEtherAmount = getEtherForTokenPrice(_tokenAddress, _tokenAmount);

        // send ether
        payable(msg.sender).transfer(getEtherAmount);

        // get token to contract
        IToken token = IToken(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);

        // decrease ether pool for token
        EtherAmounts[_tokenAddress] -= getEtherAmount;

        // decrease ether for LPs
        decreaseLPEtherPool(_tokenAddress, getEtherAmount);

        // increase token pool
        LiqAmounts[_tokenAddress] += _tokenAmount;

        // increase token for LPs
        increaseLPTokenPool(_tokenAddress, _tokenAmount);

        // Add LP fee sender?
        addToFeePool(_tokenAddress, commision);

        emit SwapTokenForEther(msg.sender, _tokenAddress, _tokenAmount, getEtherAmount);
    }

    function swapTokenForToken(address _token1Address, uint256 _token1Amount, address _token2Address) public noReentrant {
        // give token and get token
        // sell token 1, get token 2

        // token amount cant be 0
        require(_token1Amount > 0);

        // CALCULATE TOKEN1 FEE
        // calculate commision and decrease from total token
        uint256 token1Commision = (_token1Amount * (CommisionRatio / 100));
        _token1Amount -= token1Commision;

        // ether amount when token 1 sell
        uint256 getEtherAmountForToken1 = getEtherForTokenPrice(_token1Address, _token1Amount);

        // token2 amount with getted ether
        uint256 getToken2AmountWithGetEtherAmount = getTokenForEtherPrice(_token2Address, getEtherAmountForToken1);

        // get token to contract
        IToken token1 = IToken(_token1Address);
        token1.transferFrom(msg.sender, address(this), _token1Amount);

        // increase token1 pool
        LiqAmounts[_token1Address] += _token1Amount;

        // increase token1 for LPs
        increaseLPTokenPool(_token1Address, _token1Amount);

        // decrease token1 ether pool
        EtherAmounts[_token1Address] -= getEtherAmountForToken1;

        // decrease ether of token1 LPs
        decreaseLPEtherPool(_token1Address, getEtherAmountForToken1);

        // Add LP fee sender for token1Fee?
        addToFeePool(_token1Address, token1Commision);

        emit SwapTokenForEther(msg.sender, _token1Address, _token1Amount, getEtherAmountForToken1);

        // CALCULATE TOKEN2 ETHER FEE
        uint256 etherCommision = (getEtherAmountForToken1 * (CommisionRatio / 100));
        getEtherAmountForToken1 -= etherCommision;

        // increase token2 ether pool
        EtherAmounts[_token2Address] += getEtherAmountForToken1;

        // increase token2 ether LPs
        increaseLPEtherPool(_token2Address, getEtherAmountForToken1);

        // transfer token2 to user
        IToken token2 = IToken(_token2Address);
        token2.transfer(msg.sender, getToken2AmountWithGetEtherAmount);

        // decrease token2 pool
        LiqAmounts[_token2Address] -= getToken2AmountWithGetEtherAmount;

        // decrease token2 LPs
        decreaseLPTokenPool(_token2Address, getToken2AmountWithGetEtherAmount);

        // Add LP fee sender for etherFee?
        addToFeePool(address(0x0), etherCommision);

        emit SwapEtherForToken(msg.sender, _token2Address, getToken2AmountWithGetEtherAmount, getEtherAmountForToken1);
    }

    function increaseLPTokenPool(address _tokenAddress, uint256 _tokenAmount) internal {
        uint256 increasePerLP = _tokenAmount / LPList[_tokenAddress].length;
        
        for (uint256 i = 0; i < LPList[_tokenAddress].length; i++) 
        {
            TokenLPs[_tokenAddress][LPList[_tokenAddress][i]] += increasePerLP;
        }
    }

    function decreaseLPTokenPool(address _tokenAddress, uint256 _tokenAmount) internal {
        uint256 decreasePerLP = _tokenAmount / LPList[_tokenAddress].length;
        
        for (uint256 i = 0; i < LPList[_tokenAddress].length; i++) 
        {
            TokenLPs[_tokenAddress][LPList[_tokenAddress][i]] -= decreasePerLP;
        }
    }

    function increaseLPEtherPool(address _tokenAddress, uint256 _etherAmount) internal {
        uint256 increasePerLP = _etherAmount / LPList[_tokenAddress].length;
        
        for (uint256 i = 0; i < LPList[_tokenAddress].length; i++) 
        {
            EtherLPs[_tokenAddress][LPList[_tokenAddress][i]] += increasePerLP;
        }
    }

    function decreaseLPEtherPool(address _tokenAddress, uint256 _etherAmount) internal {
        uint256 decreasePerLP = _etherAmount / LPList[_tokenAddress].length;
        
        for (uint256 i = 0; i < LPList[_tokenAddress].length; i++) 
        {
            EtherLPs[_tokenAddress][LPList[_tokenAddress][i]] -= decreasePerLP;
        }
    }

    function calculateCommisionPerLP(address _tokenAddress, uint256 _totalCommision) internal view returns(uint256[] memory) {
        // Calculates commission based on order in LPList and returns as a list
        // address(0x0) uses as ether

        address[] memory LPsAtPool = LPList[_tokenAddress];
        uint256[] memory commisionPerLP = new uint256[](LPsAtPool.length);

        if (_tokenAddress == address(0x0)) {
            // ether fee calculate

            uint256 totalEtherAtPool;

            for (uint256 i = 0; i < LPsAtPool.length; i++) 
            {
                totalEtherAtPool += EtherLPs[_tokenAddress][LPsAtPool[i]];
            }

            for (uint256 i = 0; i < LPsAtPool.length; i++) 
            {
                uint256 LPsEtherForPool = EtherLPs[_tokenAddress][LPsAtPool[i]];

                // not sure about this calculation
                uint256 commisionOfLP = (LPsEtherForPool / totalEtherAtPool) * _totalCommision;
                
                commisionPerLP[i] = commisionOfLP;
            }

        } else {
            // token calculate

            uint256 totalTokenAtPool;

            for (uint256 i = 0; i < LPsAtPool.length; i++) 
            {
                totalTokenAtPool += TokenLPs[_tokenAddress][LPsAtPool[i]];
            }

            for (uint256 i = 0; i < LPsAtPool.length; i++) 
            {
                uint256 LPsTokenForPool = TokenLPs[_tokenAddress][LPsAtPool[i]];

                // not sure about this calculation
                uint256 commisionOfLP = (LPsTokenForPool / totalTokenAtPool) * _totalCommision;

                commisionPerLP[i] = commisionOfLP;
            }
        }

        return commisionPerLP;

    } 

    function addToFeePool(address _tokenAddress, uint256 _totalCommision) internal {
        // call this in all swap functions.
        // address(0x0) for ether

        // The LP with the highest odds in a pool should receive a larger share of the commission

        uint256[] memory _commisionAmountPerLP = calculateCommisionPerLP(_tokenAddress, _totalCommision);

        for (uint256 i = 0; i < LPList[_tokenAddress].length; i++) 
        {
            // send to LPs commision pool
            LPsTotalFee[LPList[_tokenAddress][i]][_tokenAddress] += _commisionAmountPerLP[i];
        }

        emit AddedToFeePool(_tokenAddress, _totalCommision);
    }

    function removeAddress(address _tokenAddress, address element) internal {
        uint length = LPList[_tokenAddress].length;
        bool found = false;
        uint index;

        // Elemanın index'ini bul
        for (uint i = 0; i < length; i++) {
            if (LPList[_tokenAddress][i] == element) {
                found = true;
                index = i;
                break;
            }
        }

        require(found, "Element not found in array");

        // Elemanı son eleman ile değiştir
        LPList[_tokenAddress][index] = LPList[_tokenAddress][length - 1];

        // Dizinin boyutunu azalt
        LPList[_tokenAddress].pop();
    }

    function calculateMyFee(address _tokenAddress) public view returns(uint256) {
        // address(0x0) is for ether
        return LPsTotalFee[_tokenAddress][msg.sender];
    }

    function getMyFee(address _tokenAddress) public noReentrant {
        // address(0x0) is for ether

        uint256 _amount = calculateMyFee(_tokenAddress);

        if (_tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            IToken token = IToken(_tokenAddress);
            token.transfer(msg.sender, _amount);
        }

        emit FeeTaken(msg.sender, _tokenAddress, _amount);
    }

    function changeCommisionRatio(uint256 _newCommisionRatio) public onlyOwner {
        CommisionRatio = _newCommisionRatio;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

}
