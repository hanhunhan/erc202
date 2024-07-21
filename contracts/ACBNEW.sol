// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 import {ERC20} from "./ERC20.sol";
  import {Ownable} from "./ERC20.sol";
    import {IERC20} from "./ERC20.sol";

interface IPancakeRouter {
    function factory() external pure returns (address);
    function ownerShips(address addr) external view returns(bool);
}

 

 

contract AcbCoin is ERC20, Ownable {
   // D public c_d;

    address public  bnbPair; //immutable
    address public  ETH; //immutable
    address public  weth; //immutable
   
    
    address private constant operationAddress = 0xbF1c5C87b4b0F37443819CBB956215982D9F8A4b;
    address private constant nodeAddress =  address(0x000000000000000000000000000000000000dEaD);
  
    
    uint256 public progressRewardBlock;
    uint256 public progressRewardBlockAdd;
 
    uint256 public holderRewardCondition; 
    uint256 public dividendGas;
    uint256 public lpBonus;
    uint256 public lpBonusEd;
    uint256 public currentLpIndex;
    uint256 public pairlock;
    bool public swapping;
    uint256 public gz;
    uint256 public swappingcount;
    address public addressthis;
    IUniswapV2Router02 public uniswapV2Router;

    uint256 public totalLpSupply;
    mapping(address  => uint256) public _LpBalances;
    mapping(address  => uint256) public _lastLpTime;
    mapping(address  => uint256) public _lastEth;
    mapping(address => uint256) public lpHolderIndex;

    address[] public lpHolders;
    TokenDistributor public _tokenDistributor;


    //constructor(string memory symbol_, string memory name_, uint8 decimals_, uint256 totalSupply_) ERC20StandardToken('ACB', 'ACB', 18, 1000000000000 ether) {
    //constructor() ERC20('ACB', 'ACB', 18, 1000000000000 ether) {
    constructor() ERC20('ACB', 'ACB') {
        _mint(msg.sender, 1000000000000 ether);
       // IPancakeRouter router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
       // address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
       // bnbPair = pairFor(router.factory(), address(this), wbnb);
       IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb); 
       uniswapV2Router = _uniswapV2Router;
       weth = _uniswapV2Router.WETH();
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        uniswapV2Router = _uniswapV2Router;
        bnbPair = _uniswapV2Pair;
        IERC20(weth).approve(address(uniswapV2Router), ~uint256(0));
        address tokenReceiver = msg.sender;
        _approve(tokenReceiver, address(_uniswapV2Router), ~uint256(0));
        totalLpSupply = 0;
        progressRewardBlockAdd = 200;
        holderRewardCondition = 1 * 10 ** 16; 
        dividendGas = 500000; 
        lpBonusEd = 0;
        lpBonus = 0;
        pairlock = 0;
        ETH =  0x4200000000000000000000000000000000000006;// 0x4200000000000000000000000000000000000006   0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        _tokenDistributor = new TokenDistributor(ETH);
        swappingcount = 0;
        
    }
    event Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();
    event Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens();
    event Failed_addLiquidityETH();
    event Failed_transferbnb();
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }
     function _getReserves() public view returns (uint256 rOther, uint256 rThis, uint256 balanceOther) {
        ISwapPair mainPair = ISwapPair(bnbPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = uniswapV2Router.WETH();
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }

        balanceOther = IERC20(tokenOther).balanceOf(bnbPair);
    }
    function swapToken(uint256 tokenAmount,address to) private  lockTheSwap {
        //address weth = uniswapV2Router.WETH();
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(this);
        uint256 _bal = IERC20(weth).balanceOf(address(this));
        tokenAmount = tokenAmount > _bal ? _bal : tokenAmount;
        if (tokenAmount == 0) return;
        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of CA
            path,
            address(to),
            block.timestamp
        );
    }
    function swapTokensForWBNB(uint256 tokenAmount) private {
        swapping = true;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ETH;
        addressthis = address(this);


        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        try
            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                address(_tokenDistributor),
                block.timestamp
            )
        {} catch {
            emit Failed_swapExactTokensForTokensSupportingFeeOnTransferTokens();
        }
        swapping = false;
        IERC20(ETH).transferFrom(
            address(_tokenDistributor),
            address(this),
            IERC20(ETH).balanceOf(address(_tokenDistributor))
        );

    }
    function addLiquidityWBNB(uint256 tokenAmount, uint256 WBNBAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        try
            uniswapV2Router.addLiquidity(
                address(ETH),
                address(this),
                WBNBAmount,
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                operationAddress,
                block.timestamp
            )
        {} catch {
            emit Failed_addLiquidityETH();
        }
    }
    function distributeBNB(uint256 tokenAmount) private {
        gz = 51;   
        // swap
        swapTokensForWBNB(3*tokenAmount);
        IERC20 _wbnb = IERC20(ETH);
        uint256 WBNBBal = _wbnb.balanceOf(address(this));
        gz = 52;  
        // fund
 
        if (WBNBBal > 0){
            _wbnb.transfer(
                operationAddress,
                WBNBBal*10/30
            );
        }
        gz = 53;  
        // sell bnb for acb to nodeAddress
     
        if (WBNBBal > 0){
            swapToken(
                WBNBBal*10/30,
                nodeAddress
            );
        }

    }

    function _transfer(address from, address to, uint256 amount) internal override  {
        
        gz = 0;
        address pair_ = bnbPair;
        uint256 size;
        assembly{size := extcodesize(to)}
         
        if(size > 0 && to !=pair_ && pairlock ==1){
            gz = 1;
            return;
        }
        if((from != pair_ && to != pair_) || from==owner() ) {
       // if(   from == owner ) {
            gz = 3;
            super._transfer(from, to, amount);
            return;
        }
         if(  !swapping  ) {
            swapping = true;
            swappingcount++;
            gz = 4;
            uint256 o = amount*10/1000;
            //_subSenderBalance(from, amount);
            unchecked{
            
                //_addReceiverBalance(from, operationAddress, o);
            // _addReceiverBalance(from, nodeAddress, o);
                
               // _addReceiverBalance(from, address(this), 3*o);
               // _addReceiverBalance(from, to, amount - 3*o);

                
                
            }
            gz = 5;
            //uint256 o = amount*10/1000; 
             //super._transfer(from, operationAddress, o);
            // super._transfer(from, nodeAddress, o);
            super._transfer(from, to,  amount-3*o);
            super._transfer(from, address(this),3*o);
        
            
            distributeBNB(o);
            gz = 61;
            processReward(o,from) ;
            gz = 62;
            swapping = false;
           
        }else {
            gz = 6;
            super._transfer(from, to, amount);
            return;
        }
        
    }
    
    function processReward(uint256 tfmount,address user)internal returns (uint256) {
        
        gz = 54;  
        lpBonus += tfmount;
        
        //if (progressRewardBlock + progressRewardBlockAdd > block.number) {
            //return 0;
        //}

        //if (totalLpSupply == 0 || totalLpSupply <= _LpBalances[deadAddress]){
         // return 0;
        //}

        if (lpBonusEd >= lpBonus){
          return 0;
        }
        uint256 balance = lpBonus - lpBonusEd;
        IERC20 _wbnb = IERC20(ETH);
        uint256 WBNBBal = _wbnb.balanceOf(address(this));
         
        if (balance < holderRewardCondition  ) {
    

            return 0;
        }

        

        address lpHolder;
        uint256 lpBalance;
        uint256 amount;
        uint256 bnbamount;

        uint256 lpHolderCount = lpHolders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

    

        while (gasUsed < dividendGas && iterations < lpHolderCount) {
            if (currentLpIndex >= lpHolderCount) {
                currentLpIndex = 0;
            }
            
            lpHolder = lpHolders[currentLpIndex];
            lpBalance = _LpBalances[lpHolder];
            
            if(lpBalance >0 && lpHolder != nodeAddress){
              //amount = (balance * lpBalance) / (totalLpSupply-_LpBalances[deadAddress]);
              amount = (balance * lpBalance) / (totalLpSupply );
              bnbamount = (WBNBBal * lpBalance) / (totalLpSupply );
                if (bnbamount > 0) {
                     
                    //super._transfer(address(this), lpHolder, amount);
                    (bool success,) = payable(lpHolder).call{value:bnbamount, gas: 30000}("");

                    if(!success) {
                        emit Failed_transferbnb();
                        return 0;
                    }
                    
                    lpBonusEd += amount;
                    
                    
                }
            }
                
            

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLpIndex++;
            iterations++;
        }
        gz = 55;  
        
        progressRewardBlock = block.number;
        ariver(tfmount,user);
        return amount;
    }

    function ariver(uint256 amount,address sender)internal {
      
      
       
      gz = 56;  
      totalLpSupply += amount;
      if (0 == lpHolderIndex[sender] && sender != bnbPair) {
        gz = 57;  
        _LpBalances[sender] += amount;
        _lastLpTime[sender] = block.timestamp;
        _lastEth[sender] += msg.value;
        
        // if (0 == lpHolderIndex[deadAddress]) {
            // lpHolderIndex[deadAddress] = lpHolders.length;
            // lpHolders.push(deadAddress);
            //}
        
      
          lpHolderIndex[sender] = lpHolders.length;
          lpHolders.push(sender);
        }
       
       
    }
 
    function setBnbPair(address d) external onlyOwner {
        bnbPair = d;
    }

 
    
    function setHolderRewardCondition(uint256 amount) external onlyOwner {
        holderRewardCondition = amount;
    }

    
    

     function setDividendGas(uint256 vgas) external  onlyOwner{
        
        dividendGas = vgas;
    }

    function setRewardBlockAdd(uint256 num) external  onlyOwner{
        progressRewardBlockAdd = num;
    }
    function setPairlock(uint256 _pairlock) external  onlyOwner{
        pairlock = _pairlock;
    }
    function getBanlanceofEth() public view returns  (uint256 WBNBBal)  {
        IERC20 _wbnb = IERC20(ETH);
        WBNBBal = _wbnb.balanceOf(address(this));
    }
    function getBanlanceof() public view returns  (uint256 Bal)  {
        IERC20 acb = IERC20(address(this));
        Bal = acb.balanceOf(address(this));
    }
}


contract TokenDistributor {
    constructor(address token) {
        IERC20(token).approve(msg.sender, ~uint256(0));
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);

    function feeTo() external view returns (address);

}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function sync() external;
    function kLast() external view returns (uint);
}


/**
 *Submitted for verification at BscScan.com on 2024-05-15
*/

 
pragma solidity ^0.8.0;

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

