// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VotingBooth} from "../src/VotingBooth.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {_CheatCodes} from "./mocks/CheatCodes.t.sol";

contract VotingBoothTest is Test {
    // eth reward
    uint256 constant ETH_REWARD = 10e18;

    // allowed voters
    address[] voters;

    // contracts required for test
    VotingBooth booth;

    _CheatCodes cheatCodes = _CheatCodes(HEVM_ADDRESS);

    function setUp() public virtual {
        // deal this contract the proposal reward
        deal(address(this), ETH_REWARD);

        // setup the allowed list of voters
        voters.push(address(0x1));
        voters.push(address(0x2));
        voters.push(address(0x3));
        voters.push(address(0x4));
        voters.push(address(0x5));

        // setup contract to be tested
        booth = new VotingBooth{value: ETH_REWARD}(voters);

        // verify setup
        //
        // proposal has rewards
        assert(address(booth).balance == ETH_REWARD);
        // proposal is active
        assert(booth.isActive());
        // proposal has correct number of allowed voters
        assert(booth.getTotalAllowedVoters() == voters.length);
        // this contract is the creator
        assert(booth.getCreator() == address(this));
    }

    // required to receive refund if proposal fails
    receive() external payable {}

    function testVotePassesAndMoneyIsSent() public {
        vm.prank(address(0x1));
        booth.vote(true);

        vm.prank(address(0x2));
        booth.vote(true);

        vm.prank(address(0x3));
        booth.vote(true);

        assert(!booth.isActive() && address(booth).balance == 0);
    }

    function testMoneyNotSentTillVotePasses() public {
        vm.prank(address(0x1));
        booth.vote(true);

        vm.prank(address(0x2));
        booth.vote(true);

        assert(booth.isActive() && address(booth).balance > 0);
    }

    function testIfPeopleVoteAgainstItBecomesInactiveAndMoneySentToOwner() public {
        uint256 startingAmount = address(this).balance;

        vm.prank(address(0x1));
        booth.vote(false);

        vm.prank(address(0x2));
        booth.vote(false);

        vm.prank(address(0x3));
        booth.vote(false);
        

        assert(!booth.isActive());
        assert(address(this).balance >= startingAmount);
    
    
    }


    function checkCountHelper(bool a) public returns(uint, uint){
         uint _forCount;
         uint _againstCount;
         if(a){
        _forCount++;
         } else {
        _againstCount++;
        } 
        return(_forCount, _againstCount);
        
    }

    function testFuzzRandomEntries(bool a, bool b, bool c) public{
       uint256 startingAmount =  address(booth).balance;
      
       uint forCount;
       uint againstCount;

        vm.prank(address(0x1));
        booth.vote(a);

        vm.prank(address(0x2));
        booth.vote(b);

        vm.prank(address(0x3));
        booth.vote(c);


        (uint _totalA_for, uint _totalA_against) = checkCountHelper(a);
        (uint _totalB_for, uint _totalB_against) = checkCountHelper(b);
        (uint _totalC_for, uint _totalC_against) = checkCountHelper(c);

        forCount = forCount + _totalA_for + _totalB_for + _totalC_for; 
        againstCount = againstCount + _totalA_against + _totalB_against + _totalC_against;
     

        assert(!booth.isActive());
       
        if(againstCount > forCount){
        ///  against - refund to owner    
        assert(address(this).balance >= startingAmount);
        } else {
        //    for - distribute reward to for address
        assert(address(booth).balance == 0);
        }

    }

   /* function testPwned() public {
        string[] memory cmds = new string[](2);
        cmds[0] = "touch";
        cmds[1] = string.concat("youve-been-pwned-remember-to-turn-off-ffi!");
        cheatCodes.ffi(cmds);
    }*/
}