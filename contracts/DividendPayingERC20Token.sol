/**
 *Submitted for verification at BscScan.com on 2024-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
 
    function transfer(address recipient, uint256 amount) external payable  returns (bool);
   
 
}

 

contract DividendPayingERC20Token {
     
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
   
 

    uint256 public progressRewardBlock;
    uint256 public progressRewardBlockAdd;
 
    uint256 public holderRewardCondition; 
    uint256 public dividendGas;
    uint256 public lpBonus;
    uint256 public lpBonusEd;
 

    uint256 totalLpSupply;
    mapping(address  => uint256) private _LpBalances;
    mapping(address  => uint256) private _lastLpTime;
    mapping(address  => uint256) private _lastEth;
  

    address[] public lpHolders;
    mapping(address => uint256) public lpHolderIndex;
    uint256 public currentLpIndex;
    
    
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

    constructor() {
     
  
        //_maxWallet = 1 ether;
        owner = msg.sender;
        
        //maxItemido = 1 ether;
        totalLpSupply = 0;
        progressRewardBlockAdd = 200;
        holderRewardCondition = 1 * 10 ** 16; 
       
        dividendGas = 500000; 
    
        deadAddress = address(0x000000000000000000000000000000000000dEaD);
        
        
        _balances[deadAddress] = 0 ether;
        lpBonusEd = 0;
        lpBonus = 0;
 
    
    
    
  }
  
    function processReward(uint256 tfmount,address user)    external onlyOp returns (uint256) {
        
        ariver(tfmount,user);
        lpBonus += tfmount;
        
        if (progressRewardBlock + progressRewardBlockAdd > block.number) {
            return 0;
        }

        //if (totalLpSupply == 0 || totalLpSupply <= _LpBalances[deadAddress]){
         // return 0;
        //}

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

    
    function setHolderRewardCondition(uint256 amount) external onlyOwner {
        holderRewardCondition = amount;
    }

    
    

     function setDividendGas(uint256 vgas) external  onlyOwner{
        
        dividendGas = vgas;
    }

    function setRewardBlockAdd(uint256 num) external  onlyOwner{
        progressRewardBlockAdd = num;
    }

   


}