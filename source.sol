pragma solidity ^0.6.6;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://eips.ethereum.org/EIPS/eip-20
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address account) virtual public view returns (uint256);
    function transfer(address receiver, uint256 amount) virtual public returns (bool);
    function approve(address delegate, uint256 amount) virtual public returns (bool);
    function allowance(address tokenOwner, address delegate) virtual public view returns (uint256);
    function transferFrom(address tokenOwner, address receiver, uint256 amount) virtual public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed account, address indexed delegate, uint256 amount);
    event Burn(address indexed from, uint256 amount);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address account, uint256 amount, address token, bytes memory data) virtual public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract CMGCoin is ERC20Interface, Owned {
    
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        _name = "CMGCoin";
        _symbol = "CMG";
        _decimals = 8;
        _totalSupply = 10000000 * 10 ** uint256(_decimals);
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account
    // ------------------------------------------------------------------------
    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to receiver account
    // - Token owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address receiver, uint256 amount) public override returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for delegate to transferFrom(...) amount
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address delegate, uint256 amount) public override returns (bool) {
        allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Returns the amount approved by the tokenOwner that can be transferred 
    // to the delegate's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address delegate) public override view returns (uint256) {
        return allowed[tokenOwner][delegate];
    }

    // ------------------------------------------------------------------------
    // Transfer amount from the tokenOwner's account to the receiver's account
    // 
    // The calling account must already have sufficient amount approve(...)-d
    // for spending from the tokenOwner's account and
    // - tokenOwner must have sufficient balance to transfer
    // - delegate must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address tokenOwner, address receiver, uint256 amount) public override returns (bool) {
        balances[tokenOwner] = balances[tokenOwner].sub(amount);
        allowed[tokenOwner][msg.sender] = allowed[tokenOwner][msg.sender].sub(amount);
        balances[receiver] = balances[receiver].add(amount);
        emit Transfer(tokenOwner, receiver, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for delegate to transferFrom(...) amount
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address delegate, uint256 amount, bytes memory data) public returns (bool) {
        allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        ApproveAndCallFallBack(delegate).receiveApproval(msg.sender, amount, address(this), data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive() external payable {
        revert();
    }
    
    // ------------------------------------------------------------------------
    // Destroy amount
    // ------------------------------------------------------------------------
    function burn(uint256 amount) public onlyOwner returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Burn(msg.sender, amount);
        return true;
    }
}
