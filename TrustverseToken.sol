pragma solidity 0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  //event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  //function renounceOwnership() public onlyOwner {
  //  emit OwnershipRenounced(owner);
  //  owner = address(0);
  //}
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, Ownable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;
  mapping(address => uint256) bonusTokens;
  mapping(address => uint256) bonusReleaseTime;
  
  mapping(address => bool) internal blacklist;
  address[] internal blacklistHistory;
  
  bool public isTokenReleased = false;
  
  address addressSaleContract;
  event BlacklistUpdated(address badUserAddress, bool registerStatus);
  event TokenReleased(address tokenOwnerAddress, bool tokenStatus);

  uint256 totalSupply_;

  modifier onlyBonusSetter() {
      require(msg.sender == owner || msg.sender == addressSaleContract);
      _;
  }

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    require(isTokenReleased);
    require(!blacklist[_to]);
    require(!blacklist[msg.sender]);
    
    if (bonusReleaseTime[msg.sender] > block.timestamp) {
        require(_value <= balances[msg.sender].sub(bonusTokens[msg.sender]));
    }
    
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    require(msg.sender == owner || !blacklist[_owner]);
    require(!blacklist[msg.sender]);
    return balances[_owner];
  }

  /**
  * @dev Set the specified address to blacklist.
  * @param _badUserAddress The address of bad user.
  */
  function registerToBlacklist(address _badUserAddress) onlyOwner public {
      if (blacklist[_badUserAddress] != true) {
	  	  blacklist[_badUserAddress] = true;
          blacklistHistory.push(_badUserAddress);
	  }
      emit BlacklistUpdated(_badUserAddress, blacklist[_badUserAddress]);   
  }
  
  /**
  * @dev Remove the specified address from blacklist.
  * @param _badUserAddress The address of bad user.
  */
  function unregisterFromBlacklist(address _badUserAddress) onlyOwner public {
      if (blacklist[_badUserAddress] == true) {
	  	  blacklist[_badUserAddress] = false;
	  }
      emit BlacklistUpdated(_badUserAddress, blacklist[_badUserAddress]);
  }

  /**
  * @dev Check the address registered in blacklist.
  * @param _address The address to check.
  * @return a bool representing registration of the passed address.
  */
  function checkBlacklist (address _address) onlyOwner public view returns (bool) {
      return blacklist[_address];
  }

  function getblacklistHistory() onlyOwner public view returns (address[]) {
      return blacklistHistory;
  }
  
  /**
  * @dev Release the token (enable all token functions).
  */
  function releaseToken() onlyOwner public {
      if (isTokenReleased == false) {
		isTokenReleased = true;
	  }
      emit TokenReleased(msg.sender, isTokenReleased);
  }
  
  /**
  * @dev Withhold the token (disable all token functions).
  */
  function withholdToken() onlyOwner public {
      if (isTokenReleased == true) {
		isTokenReleased = false;
      }
	  emit TokenReleased(msg.sender, isTokenReleased);
  }
  
  /**
  * @dev Set bonus token amount and bonus token release time for the specified address.
  * @param _tokenHolder The address of bonus token holder
  *        _bonusTokens The bonus token amount
  *        _holdingPeriodInDays Bonus token holding period (in days) 
  */  
  function setBonusTokenInDays(address _tokenHolder, uint256 _bonusTokens, uint256 _holdingPeriodInDays) onlyBonusSetter public {
      bonusTokens[_tokenHolder] = _bonusTokens;
      bonusReleaseTime[_tokenHolder] = SafeMath.add(block.timestamp, _holdingPeriodInDays * 1 days);
  }

  /**
  * @dev Set bonus token amount and bonus token release time for the specified address.
  * @param _tokenHolder The address of bonus token holder
  *        _bonusTokens The bonus token amount
  *        _bonusReleaseTime Bonus token release time
  */  
  function setBonusToken(address _tokenHolder, uint256 _bonusTokens, uint256 _bonusReleaseTime) onlyBonusSetter public {
      bonusTokens[_tokenHolder] = _bonusTokens;
      bonusReleaseTime[_tokenHolder] = _bonusReleaseTime;
  }
  
  /**
  * @dev Set bonus token amount and bonus token release time for the specified address.
  * @param _tokenHolders The address of bonus token holder ["0x...", "0x...", ...] 
  *        _bonusTokens The bonus token amount [0,0, ...] 
  *        _bonusReleaseTime Bonus token release time
  */  
  function setBonusTokens(address[] _tokenHolders, uint256[] _bonusTokens, uint256 _bonusReleaseTime) onlyBonusSetter public {
      for (uint i = 0; i < _tokenHolders.length; i++) {
        bonusTokens[_tokenHolders[i]] = _bonusTokens[i];
        bonusReleaseTime[_tokenHolders[i]] = _bonusReleaseTime;
      }
  }

  function setBonusTokensInDays(address[] _tokenHolders, uint256[] _bonusTokens, uint256 _holdingPeriodInDays) onlyBonusSetter public {
      for (uint i = 0; i < _tokenHolders.length; i++) {
        bonusTokens[_tokenHolders[i]] = _bonusTokens[i];
        bonusReleaseTime[_tokenHolders[i]] = SafeMath.add(block.timestamp, _holdingPeriodInDays * 1 days);
      }
  }

  /**
  * @dev Set the address of the crowd sale contract which can call setBonusToken method.
  * @param _addressSaleContract The address of the crowd sale contract.
  */
  function setBonusSetter(address _addressSaleContract) onlyOwner public {
      addressSaleContract = _addressSaleContract;
  }
  
  function getBonusSetter() public view returns (address) {
      require(msg.sender == addressSaleContract || msg.sender == owner);
      return addressSaleContract;
  }
  
  /**
  * @dev Display token holder's bonus token amount.
  * @param _bonusHolderAddress The address of bonus token holder.
  */
  function checkBonusTokenAmount (address _bonusHolderAddress) public view returns (uint256) {
      return bonusTokens[_bonusHolderAddress];
  }
  
  /**
  * @dev Display token holder's remaining bonus token holding period.
  * @param _bonusHolderAddress The address of bonus token holder.
  */
  function checkBonusTokenHoldingPeriodRemained (address _bonusHolderAddress) public view returns (uint256) {
      uint256 returnValue = 0;
      if (bonusReleaseTime[_bonusHolderAddress] > now) {
          returnValue = bonusReleaseTime[_bonusHolderAddress].sub(now);
      }
      return returnValue;
  }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) onlyOwner public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) onlyOwner internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
  
  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(!blacklist[_from]);
    require(!blacklist[_to]);
	require(!blacklist[msg.sender]);
    require(isTokenReleased);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(isTokenReleased);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    require(!blacklist[_owner]);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    require(!blacklist[_spender]);    
	require(!blacklist[msg.sender]);

    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

/**
 * @title TrustVerse Token
 * @dev Burnable ERC20 standard Token
 */
contract TrustVerseToken is BurnableToken, StandardToken {
  string public constant name = "TrustVerse"; // solium-disable-line uppercase
  string public constant symbol = "TRV"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase
  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));
  mapping (address => mapping (address => uint256)) internal EffectiveDateOfAllowance; // Effective date of Lost-proof, Inheritance

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }

  /**
   * @dev Transfer tokens to multiple addresses
   * @param _to array of address The address which you want to transfer to
   * @param _value array of uint256 the amount of tokens to be transferred
   */
  function transferToMultiAddress(address[] _to, uint256[] _value) public {
    require(_to.length == _value.length);

    uint256 transferTokenAmount = 0;
    uint256 i = 0;
    for (i = 0; i < _to.length; i++) {
        transferTokenAmount = transferTokenAmount.add(_value[i]);
    }
    require(transferTokenAmount <= balances[msg.sender]);

    for (i = 0; i < _to.length; i++) {
        transfer(_to[i], _value[i]);
    }
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(EffectiveDateOfAllowance[_from][msg.sender] <= block.timestamp); 
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @param _effectiveDate Effective date of Lost-proof, Inheritance
   */
  function approveWithEffectiveDate(address _spender, uint256 _value, uint256 _effectiveDate) public returns (bool) {
    require(isTokenReleased);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);
    
    EffectiveDateOfAllowance[msg.sender][_spender] = _effectiveDate;
    return approve(_spender, _value);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @param _effectiveDateInDays Effective date of Lost-proof, Inheritance
   */
  function approveWithEffectiveDateInDays(address _spender, uint256 _value, uint256 _effectiveDateInDays) public returns (bool) {
    require(isTokenReleased);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);
    
    EffectiveDateOfAllowance[msg.sender][_spender] = SafeMath.add(block.timestamp, _effectiveDateInDays * 1 days);
    return approve(_spender, _value);
  }  

  /**
   * @dev Function to check the Effective date of Lost-proof, Inheritance of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowanceEffectiveDate(address _owner, address _spender) public view returns (uint256) {
    require(!blacklist[_owner]);
    require(!blacklist[_spender]);
	require(!blacklist[msg.sender]);

    return EffectiveDateOfAllowance[_owner][_spender];
  }
}

contract PublicStageTV is Ownable {
    TrustVerseToken private TvsToken;
    address private retiroEthAddress;
    bool private isEnded = false;
    uint256 private minEth = 4 ether;
    uint256 private maxEth = 2000 ether;
    uint256 private hardCap = 152000 ether;
    uint256 private startTime = 1540310400; //2018/10/23 16:00 UTC
    uint256 private endTime = 1542643200; //2018/11/19 16:00 UTC
    uint256 private tokenLockReleaseTime = 1551369600;  //2019/02/28 16:00 UTC
    uint256 private constant tPrice = 2000;
    uint256 private weiRaised = 0;
    uint256 private weiWithdrawed = 0;
    address[] private participants;
    uint256[5] private publicRoundDate;
    uint256[5] private publicRoundRate;
    mapping(address => bool) private iskycpassed;
    mapping(address => bool) private isTvsReceived;
    mapping(address => uint256) private weiAmount;
    mapping(address => uint256) private tAmount;
    mapping(address => uint256) private bonusAmount;
    
    address private TvsOperator;

    event TvsIcoParticipationLog(address indexed participant, uint256 indexed EthAmount, uint256 TvsAmount, uint256 bonusAmount);
    event setKycResultLog(address indexed kycUser, bool indexed kycResult);
    event Transfered(address indexed retiroEthAddress, uint256 weiRaised);

    constructor() public {
        for (uint i = 0; i < 5; i++) {
            publicRoundDate[i] = 0;
            publicRoundRate[i] = 0;
        }
        publicRoundDate[0] = 1541088000; //2018/11/01 16:00
        publicRoundRate[0] = 10;
        publicRoundDate[1] = 1541865600; //2018/11/10 16:00
        publicRoundRate[1] = 5;
        retiroEthAddress = msg.sender;
    }
    
    /*
    * Getter / Setter 
    */
    function getIsEnded() public view returns (bool) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return isEnded;
    }
    
    function setMiniEth(uint _minEth) public onlyOwner {
        minEth = SafeMath.mul(_minEth, 1 ether);
    }
    
    function getMinEth() public view returns (uint) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return SafeMath.div(minEth, 1 ether);
    }

    function setMaxiEth(uint _minEth) public onlyOwner {
        minEth = SafeMath.mul(_minEth, 1 ether);
    }
    
    function getMaxEth() public view returns (uint) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return SafeMath.div(maxEth, 1 ether);
    }
    
    function setRoundDate(uint _index, uint256 _date) public onlyOwner {
        require(_index < 5);
        publicRoundDate[_index] = _date;
    }
    
    function getRoundDate(uint _index) public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        require(_index < 5);
        return publicRoundDate[_index];
    }
    
    function setRoundRate(uint _index, uint256 _date) public onlyOwner {
        require(_index < 5);
        publicRoundRate[_index] = _date;
    }
    
    function getRoundRate(uint _index) public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        require(_index < 5);
        return publicRoundRate[_index];
    }
    
    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }
     
    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }
    
    function getStartTime() public view onlyOwner returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return startTime;
    }
    
    function getEndTime() public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return endTime;
    }
    
    function getParticipatedETH(address _addr) public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator) || (msg.sender == _addr));
        return SafeMath.div(weiAmount[_addr], 1 ether);
    }
    
    function getTvsAmount(address _addr) public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator) || (msg.sender == _addr));
        return tAmount[_addr];
    }
    
    function getBonusAmount(address _addr) public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator) || (msg.sender == _addr));
        return bonusAmount[_addr];
    }
    
    function endSale() public onlyOwner {
        isEnded = true;
    }
    
    function startSale() public onlyOwner {
        isEnded = false;
    }
    
    function setKycResult(address[] _kycList, bool _kycResult) public onlyOwner {
        require(_kycResult == true || _kycResult == false);
        for (uint256 i = 0; i < _kycList.length; i++) {
            iskycpassed[_kycList[i]] = _kycResult;
            emit setKycResultLog(_kycList[i], _kycResult);
        }
    }
    
    function getKycResult(address _addr) public view returns (bool) {
        require((msg.sender == owner) || (msg.sender == TvsOperator) || (msg.sender == _addr));
        return iskycpassed[_addr];
    }
    
    function setTokenContractAddress(TrustVerseToken _tokenAddr) public onlyOwner {
        TvsToken = _tokenAddr;
    }
    
    function getTokenContractAddress() public view returns (address) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return TvsToken;
    }
    
    function setRetiroEthAddress(address _ethRetiroAddr) public onlyOwner {
        retiroEthAddress = _ethRetiroAddr;
    }
    
    function getRetiroEthAddress() public view returns (address) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return retiroEthAddress;
    }
    
    function checkEthInInteger(uint256 _pValue) private pure returns (bool) {
        uint256 ethInteger = SafeMath.div(_pValue, 1 ether);
        if (SafeMath.sub(_pValue, SafeMath.mul(ethInteger, 1 ether)) == 0) {
            return true;
        } else {
            return false;
        }
    }
    
    function getNumberOfParticipants() public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return participants.length;
    }
    
    function getWeiWithdrawaed() public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return weiWithdrawed;
    }
    
    function setTvsOperator(address _oprAddr) public onlyOwner {
        require(_oprAddr != address(0));
        TvsOperator = _oprAddr;
    }
    
    function getTvsOperator() public view returns (address) {
        require(msg.sender == owner || msg.sender == TvsOperator);
        return TvsOperator;
    }
    
    function safeEthWithdrawal() public onlyOwner {
        require(this.balance > 0);
        require(retiroEthAddress != address(0));
        uint256 withdrawalAmount = this.balance;
        if (retiroEthAddress.send(this.balance)) {
            weiWithdrawed = SafeMath.add(weiWithdrawed, withdrawalAmount);
            emit Transfered(retiroEthAddress, withdrawalAmount);
        }
    }
    
    function safeTvsDistribute() public onlyOwner {
        require(isEnded);
        for (uint256 i = 0; i < participants.length; i++) {
            if (iskycpassed[participants[i]] == true && isTvsReceived[participants[i]] == false) {
                if (participants[i] != address(0)) {
                    if(TvsToken.transfer(participants[i], SafeMath.add(tAmount[participants[i]], bonusAmount[participants[i]]))) {
                        isTvsReceived[participants[i]] = true;
                    }
                }
            }
        }
    }

    function safeTvsDistributeByIndex(uint256 _startIndex, uint256 _endIndex) public onlyOwner {
        require(isEnded);
        require(_startIndex <= _endIndex);
        require(_endIndex <= participants.length);
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            if (iskycpassed[participants[i]] == true && isTvsReceived[participants[i]] == false) {
                if (participants[i] != address(0)) {
                    if(TvsToken.transfer(participants[i], SafeMath.add(tAmount[participants[i]], bonusAmount[participants[i]]))) {
                        isTvsReceived[participants[i]] = true;
                    }
                }
            }
        }
    }

    function setHardCap(uint256 _newHardCap) public onlyOwner {
        hardCap = _newHardCap;
    }

    function getHardCap() public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return hardCap;
    }

    function getCurrentTime() public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return now;
    }
    
    function getEthRaised() public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return SafeMath.div(weiRaised, 1 ether);
    }
    
    function getTotalTvsToDistribute() public view returns (uint256) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        uint256 totalTvsToDistribute = 0;
        for (uint256 i = 0; i < participants.length; i++) {
            totalTvsToDistribute = SafeMath.add(tAmount[participants[i]], totalTvsToDistribute);
            totalTvsToDistribute = SafeMath.add(bonusAmount[participants[i]], totalTvsToDistribute);
        }
        return totalTvsToDistribute;
    }
    
    function getIsTvsReceived(address _rcvrAddr) public view returns (bool) {
        require((msg.sender == owner) || (msg.sender == TvsOperator));
        return isTvsReceived[_rcvrAddr];
    }
    
    function safeTvsWithdrawal() public onlyOwner {
        uint256 remainingTvs = TvsToken.balanceOf(this);
        if (remainingTvs > 0) {
            TvsToken.transfer(owner, remainingTvs);
        }
    }
    /*
    * fallback function
    */
    function () external payable {
        require(!isEnded);
        require(msg.value != 0);
        require(minEth <= msg.value);
        require(msg.value <= maxEth);
        require(startTime <= now);
        require(now <= endTime);
        require(TvsToken != address(0));
        require(retiroEthAddress != address(0));
        require(retiroEthAddress != msg.sender);
        require(checkEthInInteger(msg.value));
        require(TvsToken.getBonusSetter() != address(0));
        
        //If reaches hardcap or personal cap, do refund processing
        uint256 weisToRefundPersonalCap = SafeMath.add(weiAmount[msg.sender], msg.value);
        uint256 weisToRefundHardCap = SafeMath.add(weiRaised, msg.value);
        uint256 comittedEths = msg.value;
        
        if (weisToRefundPersonalCap > maxEth) {
            weisToRefundPersonalCap = SafeMath.sub(weisToRefundPersonalCap, maxEth);
        } else {
            weisToRefundPersonalCap = 0;
        }
        
        if (weisToRefundHardCap > hardCap) {
            weisToRefundHardCap = SafeMath.sub(weisToRefundHardCap, hardCap);
        } else {
            weisToRefundHardCap = 0;
        }
        
        if ((weisToRefundHardCap > 0) || (weisToRefundPersonalCap > 0)) {
            if (weisToRefundPersonalCap > weisToRefundHardCap) {
                comittedEths = SafeMath.sub(msg.value, weisToRefundPersonalCap);
                msg.sender.transfer(weisToRefundPersonalCap);
                //emit Transfered
            } else {
                comittedEths = SafeMath.sub(msg.value, weisToRefundHardCap);
                msg.sender.transfer(weisToRefundHardCap);
                //emit Transfered
            }
        }
        
        //add to participants list if first timer.
        if (weiAmount[msg.sender] <= 0) {
            participants.push(msg.sender);
        }

        weiAmount[msg.sender] = SafeMath.add(weiAmount[msg.sender], comittedEths);
        tAmount[msg.sender] = SafeMath.add(tAmount[msg.sender], SafeMath.mul(comittedEths, tPrice));
        for (uint i = 0; i < 5; i++) {
            if (now < publicRoundDate[i]) {
                bonusAmount[msg.sender] = SafeMath.add(bonusAmount[msg.sender], SafeMath.div(SafeMath.mul(SafeMath.mul(comittedEths, tPrice),publicRoundRate[i]),100));
                i = 10;
                break;
            }
        }
        TvsToken.setBonusToken(msg.sender, bonusAmount[msg.sender], tokenLockReleaseTime); //set bonus token lock
        weiRaised = SafeMath.add(weiRaised, comittedEths);
        
        // immediately withdrawal ETH
        uint256 withdrawalAmount = this.balance;
        if (retiroEthAddress.send(withdrawalAmount)) {
            weiWithdrawed = SafeMath.add(weiWithdrawed, withdrawalAmount);
            emit Transfered(retiroEthAddress, withdrawalAmount);
        }
    }
    //emit TvsIcoParticipationLog(address indexed participant, uint256 indexed EthAmount, uint256 TvsAmount, uint256 bonusAmount);
}
