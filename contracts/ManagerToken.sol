// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ManagerToken is AccessControlEnumerable, ERC20Capped {
  bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");
  uint256 _cap;
  uint256 _targetReserve;
  uint256 _mgmtFee;
  uint256 _feeBasis;

  constructor(string memory name_, string memory symbol_, uint256 cap_, uint256 mgmtFee_) ERC20(name_, symbol_) ERC20Capped(cap_) { 
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(CLAIMER_ROLE, _msgSender());
    _mgmtFee = mgmtFee_; // Fee in thousands
    _feeBasis = 1000;
  }

  function mint(address account, uint256 amount) public virtual {
    super._mint(account, amount);
  }

  // Return the value of the contract in eth
  function totalEquity() public virtual returns uint256 {
    // TODO:
    return 1000
  }

  function _calculateEquity(uint256 tokenAmount) private virtual returns uint256 {
    uint256 nonFeeAmount = tokenAmount * _mgmtFee / _feeBasis;
    uint256 totalValue = getValue();
    return nonFeeAmount/totalSupply() * totalValue;
  }

  function myEquity() public virtual returns uint256 {
    uint256 amount = balanceOf(_msgSender());
    return _calculateEquity(amount)
  }

  function burn(uint256 amount) public virtual {
    uint256 callerEquity = myEquity();

    uint256 reserveBalance = address(this).balance;
    require(reserveBalance >= callerEquity, "Reserve does not have enough balance, try calling hardBurn");

    _msgSender().transfer(callerEquity);
    super._burn(_msgSender(), amount); // TODO: can msg.sender be a 0 address?
  }

  // Execute rebalance witholding equity amount and then burns the token
  function hardBurn(uint256 tokenAmount) public virtual {
    uint256 targetEquity = _calculateEquity(tokenAmount);
    require(targetEquity >= totalEquity(), "Not enough equity for a hardBurn");
    rebalance(targetEquity);
    burn(tokenAmount);
    emit HardBurn(amount);
  }

  function rebalance(uint256 additionalEquity) public virtual {
    // Calculate midprice of pair
    // + / - a target % gain
    // Sell everything
    // withold reserve

  }

  function claimFee(uint256 percentage) public virtual {
    require(hasRole(CLAIMER_ROLE), _msgSender(), "Public key can not claimFee");
    uint256 myBalance = balanceOf(address(this));
    transfer(address(this), myBalance*percentage/100);
  }

  //function ccap() public returns (uint256) {
    //return _cap;
  //}

  
  //function rebalance() public virtual {
    //// check to see if sender can call rebalance
    //// sell everything & set aside reserve
    //// re enter everything

  //}

}
