// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  mapping (address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 deadline = block.timestamp + 30 seconds;
  uint256 stakeAmount=0;
  address payable owner;
  bool openForWithdraw;
  event Stake(address indexed _owner,uint balance);



  function stake() public payable {
      require(block.timestamp<=deadline,"You cant stake after the stake time");
      stakeAmount += msg.value;
      require(msg.value>=0,"You need to stake above 0 Ether");
      balances[msg.sender] += msg.value;
      owner=payable(msg.sender);
      emit Stake(msg.sender,balances[msg.sender]);
  }

  

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public{
    require(address(this).balance>=threshold,"You cant withdraw before the threshold amount");
    require(block.timestamp>=deadline,"You cant withdraw before the deadline");
    if(address(this).balance<=threshold){
      openForWithdraw = true;
    }

    (bool sent,) = address(exampleExternalContract).call{value: address(this).balance}(abi.encodeWithSignature("complete()"));
    require(sent, "exampleExternalContract.complete failed");
  }

  
  function timeLeft() public view returns (uint256 timeleft) {
    if( block.timestamp >= deadline ) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public  {
    uint256 userBalance = balances[msg.sender];
 
    // check if the user has balance to withdraw
    require(userBalance > 0, "You don't have balance to withdraw");
    require(block.timestamp>=deadline,"You cant withdraw before the threshold");
    require(msg.sender==owner,"You are not the owner");

    // reset the balance of the user
    balances[msg.sender] = 0;

    // Transfer balance back to the user
    (bool sent,) = msg.sender.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }


  // Add the `receive()` special function that receives eth and calls stake()
  function recieve() external payable {
    stake();
  }


}
