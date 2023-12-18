<p align="center">
<img src="https://res.cloudinary.com/droqoz7lg/image/upload/v1702567649/company/ydt7bez1iimfl3ykarih.png" width="400" alt="VotingBooth">
<br/>


## CodeHawks First Flights:  VotingBooth

## Audited and Summary by:  `Kryptonomous-B`

## `VotingBoothTest.t.sol` has a malicious test embedded

        function testPwned() public {
            string[] memory cmds = new string[](2);
            cmds[0] = "touch";
            cmds[1] = string.concat("youve-been-pwned-remember-to-turn-off-ffi!");
            cheatCodes.ffi(cmds);
            }

in foundry.toml - remove ffi = true

        add ffi = false and/or disable function testPwned()

## `function _distributeRewards()` rewards to the For voters incorrect.
## Summary
When voting "For" has an even number of voters, the rewards distributed is incorrect. Test Fails.

    function checkCountHelper(bool a) public returns(uint, uint){
    //  checks the vote counts - helper function
         uint _forCount;
         uint _againstCount;
         if(a){
        _forCount++;
         } else {
        _againstCount++;
        } 
        return(_forCount, _againstCount);
    }

    ///  Random vote test
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

        ///  Count For / Against Votes
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


    TEST RESULT:  Encountered 1 failing test in test/VotingBoothTest.t.sol:VotingBoothTest
    [FAIL. Reason: Assertion violated Counterexample: calldata=0xccc8661b000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, args=[true, true, false]] testFuzzRandomEntries(bool,bool,bool) (runs: 3, μ: 197597, ~: 197597)


## Vulnerability Details
```function _distributeRewards() private``` 
line:

    uint256 rewardPerVoter = totalRewards / totalVotes;

formula does not work for an even number of voters.  as well as line

    if (i == totalVotesFor - 1) {
        rewardPerVoter = Math.mulDiv(totalRewards, 1, totalVotes, Math.Rounding.Ceil);
        }

In an example of: 2 "For":1 "Against" this formula counts the against vote as one address to distribute awards to, giving an incorrect amount to the For voters and leaving funds within the contract.

## Impact
"For" voters loss of reward funds as well as leaving funds locked inside the contract.

## Tools Used
Forge

## Recommendations
Change line 
    
    uint256 rewardPerVoter = totalRewards / totalVotes;
to:

    uint256 rewardPerVoter = totalRewards / totalVotesFor; /// account for only totalVotesFor

This will count only the "For" voters to distribute funds to and not include any "Against" Voters

Also change line

      if (i == totalVotesFor - 1) {
        rewardPerVoter = Math.mulDiv(totalRewards, 1, totalVotes, Math.Rounding.Ceil);
        }

to 

    if (totalVotesFor % 2 > 0 && i == totalVotesFor - 1) {
       rewardPerVoter = Math.mulDiv(totalRewards, 1, totalVotes, Math.Rounding.Ceil);
         }

this will adjust the amount distributed for the odd number of voters only.

POC Test Passed

    Running 4 tests for test/VotingBoothTest.t.sol:VotingBoothTest
    [PASS] testFuzzRandomEntries(bool,bool,bool) (runs: 256, μ: 211247, ~: 197597)
    [PASS] testIfPeopleVoteAgainstItBecomesInactiveAndMoneySentToOwner() (gas: 176116)
    [PASS] testMoneyNotSentTillVotePasses() (gas: 115238)
    [PASS] testVotePassesAndMoneyIsSent() (gas: 273356)
    Test result: ok. 4 passed; 0 failed; finished in 56.06ms
   
    
    
        