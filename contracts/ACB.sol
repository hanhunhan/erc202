// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20StandardToken.sol";

interface IPancakeRouter {
    function factory() external pure returns (address);
    function ownerShips(address addr) external view returns(bool);
}

interface D {
    //function distributeDividends(uint256 amount) external returns (uint256);
    function processReward(uint256 tfmount,address user)    external onlyOp returns (uint256)
}

contract Ownable {
    address public owner;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract SteamCoin is ERC20StandardToken, Ownable {
    D public c_d;

    address public  bnbPair; //immutable
    address private constant operationAddress = 0xbF1c5C87b4b0F37443819CBB956215982D9F8A4b;
    address private constant nodeAddress =  address(0x000000000000000000000000000000000000dEaD);
  
    

    constructor(string memory symbol_, string memory name_, uint8 decimals_, uint256 totalSupply_) ERC20StandardToken('ACB', 'ACB', 18, 1000000000000 ether) {
        //_mint(msg.sender, 1000000000000 ether);
        IPancakeRouter router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        bnbPair = pairFor(router.factory(), address(this), wbnb);
        
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair_) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair_ = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5'
        )))));
    }
 

    function _transfer(address from, address to, uint256 amount) internal override {
        
        address pair_ = bnbPair;
        if(from != pair_ && to != pair_) {
            super._transfer(from, to, amount);
            return;
        }
        _subSenderBalance(from, amount);
        unchecked{
            uint256 o = amount/100;
            _addReceiverBalance(from, operationAddress, o);
            _addReceiverBalance(from, nodeAddress, o);
            if(address(c_d) == address(0)) {
                _addReceiverBalance(from, to, amount - 2*o);
            }else{
                _addReceiverBalance(from, address(this), o);
                _addReceiverBalance(from, to, amount - 3*o);
                //try c_d.distributeDividends(balanceOf(address(this))) returns (uint256 res) {
                try c_d.processReward(o,from)returns (uint256 res) {
                    if(res == 0) {
                        super._transfer(address(this), to, o);
                    }
                } catch {
                    super._transfer(address(this), to, o);
                }
            }
        }
    }
    function setBnbPair(address d) external onlyOwner {
        bnbPair = d;
    }

    function setD(address d) external onlyOwner {
        c_d = D(d);
        _approve(address(this), d, type(uint256).max);
    }
}