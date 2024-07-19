/**
 *Submitted for verification at BscScan.com on 2024-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
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
 

contract DividendPayingERC20Token {
     
   
 

    uint256 public progressRewardBlock;
    uint256 public progressRewardBlockAdd;
 
    uint256 public holderRewardCondition; 
    uint256 public dividendGas;
    uint256 public lpBonus;
    uint256 public lpBonusEd;
    uint256 public currentLpIndex;

    uint256 public totalLpSupply;
    mapping(address  => uint256) public _LpBalances;
    mapping(address  => uint256) public _lastLpTime;
    mapping(address  => uint256) public _lastEth;
    mapping(address => uint256) public lpHolderIndex;

    address[] public lpHolders;
    address public op;
    address public owner;
    
    
    
    address private  deadAddress;

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
        holderRewardCondition = 1 * 10 ** 10; 
       
        dividendGas = 500000; 
    
        deadAddress = address(0x000000000000000000000000000000000000dEaD);
        
        
       
        lpBonusEd = 0;
        lpBonus = 0;
 
    
    
    
  }
  
    function processReward(uint256 tfmount,address user)payable external onlyOp returns (uint256) {
        
        ariver(tfmount,user);
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
        //if (balance < holderRewardCondition ||  IERC20(msg.sender).balanceOf(msg.sender) < holderRewardCondition ) {
        if (balance < holderRewardCondition  ) {
    

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
              //amount = (balance * lpBalance) / (totalLpSupply-_LpBalances[deadAddress]);
              amount = (balance * lpBalance) / (totalLpSupply );
                if (amount > 0) {
                    //(bool success,) = lpHolder.call{value: amount}(""); 
                    IERC20(msg.sender).transferFrom(msg.sender,lpHolder,amount); 
                   
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

    function ariver(uint256 amount,address sender)internal {
      
      
       
      
      totalLpSupply += amount;
      _LpBalances[sender] += amount;
      _lastLpTime[sender] = block.timestamp;
       _lastEth[sender] += msg.value;
       
       // if (0 == lpHolderIndex[deadAddress]) {
         // lpHolderIndex[deadAddress] = lpHolders.length;
         // lpHolders.push(deadAddress);
        //}
      
      if (0 == lpHolderIndex[sender]) {
          lpHolderIndex[sender] = lpHolders.length;
          lpHolders.push(sender);
        }
       
       
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