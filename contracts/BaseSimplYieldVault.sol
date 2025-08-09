// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Self-contained contract without OpenZeppelin dependencies
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

// Basic ERC20 implementation
contract ERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
    
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
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
    
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: mint to zero address");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "ERC20: burn from zero address");
        require(_balances[from] >= amount, "ERC20: burn amount exceeds balance");
        
        _balances[from] -= amount;
        _totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}

// Simple ownership
abstract contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    function owner() public view returns (address) { return _owner; }
    
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

// ReentrancyGuard
abstract contract ReentrancyGuard {
    bool private _locked;
    
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }
}

/**
 * @title BaseSimpleVault
 * @dev A simple yield vault for Base network that accepts ETH deposits
 * @author YourName - Base Builder Rewards Candidate
 */
contract BaseSimpleVault is ERC20, ReentrancyGuard, Ownable {
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 shares, uint256 amount);
    event YieldDistributed(uint256 amount);
    
    // State variables
    uint256 public totalAssets;
    uint256 public lastYieldDistribution;
    uint256 public constant YIELD_RATE = 5; // 5% annual yield simulation
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    
    mapping(address => uint256) public lastDepositTime;
    
    constructor() ERC20("Base Simple Vault Token", "BSV") {
        lastYieldDistribution = block.timestamp;
    }
    
    /**
     * @dev Deposit ETH and receive vault shares
     */
    function deposit() external payable nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        uint256 shares;
        if (totalSupply() == 0) {
            shares = msg.value;
        } else {
            shares = (msg.value * totalSupply()) / totalAssets;
        }
        
        totalAssets += msg.value;
        lastDepositTime[msg.sender] = block.timestamp;
        
        _mint(msg.sender, shares);
        
        emit Deposit(msg.sender, msg.value, shares);
    }
    
    /**
     * @dev Withdraw assets by burning vault shares
     */
    function withdraw(uint256 shares) external nonReentrant {
        require(shares > 0, "Shares must be greater than 0");
        require(balanceOf(msg.sender) >= shares, "Insufficient shares");
        
        // Calculate assets to return
        uint256 assets = (shares * totalAssets) / totalSupply();
        
        totalAssets -= assets;
        _burn(msg.sender, shares);
        
        // Transfer ETH back to user
        (bool success, ) = msg.sender.call{value: assets}("");
        require(success, "ETH transfer failed");
        
        emit Withdraw(msg.sender, shares, assets);
    }
    
    /**
     * @dev Simulate yield generation and distribute to vault
     */
    function distributeYield() external {
        require(block.timestamp > lastYieldDistribution + 1 hours, "Too soon for yield distribution");
        
        if (totalAssets > 0) {
            uint256 timeElapsed = block.timestamp - lastYieldDistribution;
            uint256 yieldAmount = (totalAssets * YIELD_RATE * timeElapsed) / (100 * SECONDS_PER_YEAR);
            
            // Simulate yield by increasing total assets
            totalAssets += yieldAmount;
            lastYieldDistribution = block.timestamp;
            
            emit YieldDistributed(yieldAmount);
        }
    }
    
    /**
     * @dev Emergency function to add yield manually (for testing)
     */
    function addYield() external payable onlyOwner {
        totalAssets += msg.value;
        emit YieldDistributed(msg.value);
    }
    
    /**
     * @dev Get the current exchange rate of shares to assets
     */
    function getExchangeRate() external view returns (uint256) {
        if (totalSupply() == 0) return 1e18;
        return (totalAssets * 1e18) / totalSupply();
    }
    
    /**
     * @dev Get user's asset balance based on their shares
     */
    function getUserAssetBalance(address user) external view returns (uint256) {
        uint256 userShares = balanceOf(user);
        if (userShares == 0 || totalSupply() == 0) return 0;
        return (userShares * totalAssets) / totalSupply();
    }
    
    /**
     * @dev Get estimated APY based on recent yield distributions
     */
    function getEstimatedAPY() external pure returns (uint256) {
        return YIELD_RATE;
    }
    
    /**
     * @dev Get time until next yield distribution is available
     */
    function getTimeToNextYield() external view returns (uint256) {
        uint256 nextYieldTime = lastYieldDistribution + 1 hours;
        if (block.timestamp >= nextYieldTime) return 0;
        return nextYieldTime - block.timestamp;
    }
}
