/**
 *Submitted for verification at BscScan.com on 2024-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

contract DividendPayingERC20Token {
    using SafeMathUint for uint256;
    using SafeMathInt for int256;
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    uint256 private totalDividendsDistributed;
  
    uint256 constant private magnitude = 10**23;
    mapping(address => int256) public magnifiedDividendCorrections;
    mapping(address => uint256) private withdrawnDividends;

    uint256 public magnifiedDividendPerShare;

    uint256 public progressRewardBlock;
    uint256 public progressRewardBlockAdd;
    uint256 public holderCondition;
    uint256 public holderRewardCondition; 
    uint256 public dividendGas;
    uint256 public lpBonus;
    uint256 public lpBonusEd;

    uint256 totalLpSupply;
    mapping(address  => uint256) private _LpBalances;
    mapping(address  => uint256) private _lastLpTime;
    mapping(address  => uint256) private _lastEth;
    mapping(address  => uint256) private _lastToken;

    address[] public lpHolders;
    mapping(address => uint256) public lpHolderIndex;
    uint256 public currentLpIndex;
    
    

    IERC20 private constant c_erc20 = IERC20(0x65e74abE9190b5015fdd548593cA348b981A4636);
    IERC20 private constant c_lp = IERC20(0x58bEf2351A4f43f086802fB35434Fd7764135968);

    address private  deadAddress;
    address public op;
    address public owner;
    modifier onlyOp() {
        require(op == msg.sender, "Ownable: caller is not the op");
        _;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor( ) {
     
  
        //_maxWallet = 1 ether;
        owner = msg.sender;
        
        //maxItemido = 1 ether;

        progressRewardBlockAdd = 200;
        holderRewardCondition = 1 * 10 ** 16; 
        holderCondition = 5000 * 10 ** 18;
        dividendGas = 500000; 
    
        deadAddress = address(0x000000000000000000000000000000000000dEaD);
        
        
        _balances[deadAddress] = 0 ether;
 
    
    
    
  }
  
    function processReward(uint256 tfmount,address user)    external onlyOp returns (uint256) {
        
        ariver(tfmount,user);
        
        if (progressRewardBlock + progressRewardBlockAdd > block.number) {
            return 0;
        }

        if (totalLpSupply == 0 || totalLpSupply <= _LpBalances[deadAddress]){
          return 0;
        }

        if (lpBonusEd >= lpBonus){
          return 0;
        }
        uint256 balance = lpBonus - lpBonusEd;
        if (balance < holderRewardCondition || address(this).balance < holderRewardCondition) {
            return 0;
        }

        

        address lpHolder;
        uint256 lpBalance;
        uint256 amount;

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
            
            if(lpBalance >0 && lpHolder != deadAddress){
              amount = (balance * lpBalance) / (totalLpSupply-_LpBalances[deadAddress]);
                if (amount > 0) {
                    //(bool success,) = lpHolder.call{value: amount}(""); 
                    IERC20(msg.sender).transfer(lpHolder,amount); 
                    //if (success) {
                        lpBonusEd += amount;
                    //}
                    
                }
            }
                
            

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLpIndex++;
            iterations++;
        }

        progressRewardBlock = block.number;
        return amount;
    }

    function ariver(uint256 amount,address sender)internal virtual   {
      
      
       
      
      totalLpSupply += amount;
      _LpBalances[sender] += amount;
      _lastLpTime[sender] = block.timestamp;
       _lastEth[sender] += msg.value;
       
        if (0 == lpHolderIndex[deadAddress]) {
          lpHolderIndex[deadAddress] = lpHolders.length;
          lpHolders.push(deadAddress);
        }
      
      if (0 == lpHolderIndex[sender]) {
          lpHolderIndex[sender] = lpHolders.length;
          lpHolders.push(sender);
        }
       
       
    }
 
 
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function setOp(address d) external onlyOwner {
        op = d;
    }

    function contractInfo() external view returns(uint256, uint256) {
        return (_totalSupply, totalDividendsDistributed);
    }
}