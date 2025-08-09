// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Self-contained ERC20 token launcher for Base network
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Basic ERC20 Token Template
contract BaseToken is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _tokenOwner;
    
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address owner_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = totalSupply_ * 10**_decimals;
        _tokenOwner = owner_;
        _balances[owner_] = _totalSupply;
        emit Transfer(address(0), owner_, _totalSupply);
    }
    
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; }
    function tokenOwner() public view returns (address) { return _tokenOwner; }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function allowance(address tokenOwnerAddr, address spender) public view returns (uint256) {
        return _allowances[tokenOwnerAddr][spender];
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        _transfer(from, to, amount);
        _approve(from, msg.sender, currentAllowance - amount);
        
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
    
    function _approve(address tokenOwnerAddr, address spender, uint256 amount) internal {
        require(tokenOwnerAddr != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");
        
        _allowances[tokenOwnerAddr][spender] = amount;
        emit Approval(tokenOwnerAddr, spender, amount);
    }
}

/**
 * @title BaseTokenLauncher
 * @dev Launch ERC20 tokens on Base network with built-in liquidity features
 * @author YourName - Base Builder Rewards Candidate
 */
contract BaseTokenLauncher {
    
    // Events
    event TokenLaunched(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        uint256 totalSupply
    );
    
    event LiquidityAdded(
        address indexed token,
        address indexed provider,
        uint256 tokenAmount,
        uint256 ethAmount
    );
    
    event TokenPurchased(
        address indexed buyer,
        address indexed token,
        uint256 ethSpent,
        uint256 tokensReceived
    );
    
    // Structs
    struct LaunchedToken {
        address tokenAddress;
        address creator;
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 launchTime;
        uint256 liquidityPool; // ETH in liquidity
        bool isActive;
    }
    
    // State variables
    mapping(address => LaunchedToken) public launchedTokens;
    address[] public tokenList;
    mapping(address => mapping(address => uint256)) public liquidityProvided;
    
    uint256 public constant LAUNCH_FEE = 0.001 ether; // Small fee for launches
    uint256 public constant MIN_LIQUIDITY = 0.01 ether; // Minimum ETH for liquidity
    
    address public owner;
    uint256 public totalTokensLaunched;
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Launch a new ERC20 token with initial liquidity
     */
    function launchToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 tokensForLiquidity
    ) external payable {
        require(msg.value >= LAUNCH_FEE + MIN_LIQUIDITY, "Insufficient payment");
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(symbol).length > 0, "Symbol cannot be empty");
        require(totalSupply > 0, "Total supply must be greater than 0");
        require(tokensForLiquidity <= totalSupply, "Liquidity tokens exceed total supply");
        
        // Deploy new token contract
        BaseToken newToken = new BaseToken(name, symbol, totalSupply, msg.sender);
        address tokenAddress = address(newToken);
        
        // Store token information
        launchedTokens[tokenAddress] = LaunchedToken({
            tokenAddress: tokenAddress,
            creator: msg.sender,
            name: name,
            symbol: symbol,
            totalSupply: totalSupply,
            launchTime: block.timestamp,
            liquidityPool: msg.value - LAUNCH_FEE,
            isActive: true
        });
        
        tokenList.push(tokenAddress);
        totalTokensLaunched++;
        
        // Add initial liquidity
        if (tokensForLiquidity > 0) {
            liquidityProvided[tokenAddress][msg.sender] = tokensForLiquidity;
        }
        
        emit TokenLaunched(tokenAddress, msg.sender, name, symbol, totalSupply);
        
        if (msg.value > LAUNCH_FEE) {
            emit LiquidityAdded(tokenAddress, msg.sender, tokensForLiquidity, msg.value - LAUNCH_FEE);
        }
    }
    
    /**
     * @dev Add liquidity to a launched token
     */
    function addLiquidity(address tokenAddress, uint256 tokenAmount) external payable {
        require(launchedTokens[tokenAddress].isActive, "Token not found or inactive");
        require(msg.value > 0, "Must provide ETH");
        require(tokenAmount > 0, "Must provide tokens");
        
        // Transfer tokens from user to this contract
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");
        
        // Update liquidity records
        launchedTokens[tokenAddress].liquidityPool += msg.value;
        liquidityProvided[tokenAddress][msg.sender] += tokenAmount;
        
        emit LiquidityAdded(tokenAddress, msg.sender, tokenAmount, msg.value);
    }
    
    /**
     * @dev Simple token purchase mechanism
     */
    function buyToken(address tokenAddress) external payable {
        require(launchedTokens[tokenAddress].isActive, "Token not found or inactive");
        require(msg.value > 0, "Must provide ETH");
        
        LaunchedToken storage tokenInfo = launchedTokens[tokenAddress];
        require(tokenInfo.liquidityPool > 0, "No liquidity available");
        
        // Simple bonding curve: tokens = eth * multiplier / price_factor
        uint256 tokensToSend = (msg.value * 1000) / (tokenInfo.liquidityPool / 1e15 + 1);
        
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= tokensToSend, "Insufficient token liquidity");
        
        // Update liquidity pool
        tokenInfo.liquidityPool += msg.value;
        
        // Transfer tokens to buyer
        require(token.transfer(msg.sender, tokensToSend), "Token transfer failed");
        
        emit TokenPurchased(msg.sender, tokenAddress, msg.value, tokensToSend);
    }
    
    /**
     * @dev Get token information
     */
    function getTokenInfo(address tokenAddress) external view returns (
        address creator,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint256 launchTime,
        uint256 liquidityPool,
        bool isActive
    ) {
        LaunchedToken storage token = launchedTokens[tokenAddress];
        return (
            token.creator,
            token.name,
            token.symbol,
            token.totalSupply,
            token.launchTime,
            token.liquidityPool,
            token.isActive
        );
    }
    
    /**
     * @dev Get list of all launched tokens
     */
    function getAllTokens() external view returns (address[] memory) {
        return tokenList;
    }
    
    /**
     * @dev Get token price estimate
     */
    function getTokenPrice(address tokenAddress) external view returns (uint256) {
        LaunchedToken storage tokenInfo = launchedTokens[tokenAddress];
        if (tokenInfo.liquidityPool == 0) return 0;
        
        return (tokenInfo.liquidityPool / 1e15 + 1); // Simple pricing
    }
    
    /**
     * @dev Emergency function to deactivate a token
     */
    function deactivateToken(address tokenAddress) external {
        require(msg.sender == launchedTokens[tokenAddress].creator || msg.sender == owner, "Not authorized");
        launchedTokens[tokenAddress].isActive = false;
    }
    
    /**
     * @dev Withdraw accumulated fees (owner only)
     */
    function withdrawFees() external {
        require(msg.sender == owner, "Only owner can withdraw fees");
        uint256 balance = address(this).balance;
        
        // Keep some ETH for liquidity operations
        uint256 withdrawAmount = balance > 0.1 ether ? balance - 0.05 ether : 0;
        
        if (withdrawAmount > 0) {
            (bool success, ) = owner.call{value: withdrawAmount}("");
            require(success, "Withdrawal failed");
        }
    }
    
    /**
     * @dev Get contract statistics
     */
    function getStats() external view returns (
        uint256 totalTokens,
        uint256 totalLiquidity,
        uint256 activeTokens
    ) {
        totalLiquidity = address(this).balance;
        
        uint256 active = 0;
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (launchedTokens[tokenList[i]].isActive) {
                active++;
            }
        }
        
        return (totalTokensLaunched, totalLiquidity, active);
    }
    
    // Receive ETH
    receive() external payable {
        // Allow contract to receive ETH
    }
}