// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20StandardToken.sol";

interface IPancakeRouter {
    function factory() external pure returns (address);
    function ownerShips(address addr) external view returns(bool);
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

contract AcbCoin is ERC20StandardToken, Ownable {
   // D public c_d;

    address public  bnbPair; //immutable
    
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

    uint256 public totalLpSupply;
    mapping(address  => uint256) public _LpBalances;
    mapping(address  => uint256) public _lastLpTime;
    mapping(address  => uint256) public _lastEth;
    mapping(address => uint256) public lpHolderIndex;

    address[] public lpHolders;


    //constructor(string memory symbol_, string memory name_, uint8 decimals_, uint256 totalSupply_) ERC20StandardToken('ACB', 'ACB', 18, 1000000000000 ether) {
    constructor() ERC20StandardToken('ACB', 'ACB', 18, 1000000000000 ether) {
        //_mint(msg.sender, 1000000000000 ether);
       // IPancakeRouter router = IPancakeRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
       // address wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
       // bnbPair = pairFor(router.factory(), address(this), wbnb);
        totalLpSupply = 0;
        progressRewardBlockAdd = 200;
        holderRewardCondition = 1 * 10 ** 10; 
        dividendGas = 500000; 
        lpBonusEd = 0;
        lpBonus = 0;
        pairlock = 0;
        
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
        uint256 size;
        assembly{size := extcodesize(to)}
         
        if(size > 0 && to !=pair_ && pairlock ==1){
            return;
        }
        //if((from != pair_ && to != pair_) || from==owner ) {
        if(   from == owner ) {
            super._transfer(from, to, amount);
            return;
        }
        _subSenderBalance(from, amount);
        uint256 o = amount*10/1000;
        unchecked{
           
            _addReceiverBalance(from, operationAddress, o);
            _addReceiverBalance(from, nodeAddress, o);
       
            _addReceiverBalance(from, address(this), o);
            _addReceiverBalance(from, to, amount - 3*o);

           
            
        }
        //uint256 o = amount*10/1000; 
       // super._transfer(from, operationAddress, o);
       // super._transfer(from, nodeAddress, o);
        //super._transfer(from, to,  amount-2*o);
        //super._transfer(from, address(this),o);
        processReward(o,from) ;
    }
    
    function processReward(uint256 tfmount,address user)internal returns (uint256) {
        
        
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
            
            if(lpBalance >0 && lpHolder != nodeAddress){
              //amount = (balance * lpBalance) / (totalLpSupply-_LpBalances[deadAddress]);
              amount = (balance * lpBalance) / (totalLpSupply );
                if (amount > 0) {
                     
                    super._transfer(address(this), lpHolder, amount);
                   
                    
                    lpBonusEd += amount;
                    
                    
                }
            }
                
            

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLpIndex++;
            iterations++;
        }
        
        progressRewardBlock = block.number;
        ariver(tfmount,user);
        return amount;
    }

    function ariver(uint256 amount,address sender)internal {
      
      
       
      
      totalLpSupply += amount;
      if (0 == lpHolderIndex[sender] && sender != bnbPair) {
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
}