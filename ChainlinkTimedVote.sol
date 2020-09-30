pragma solidity ^0.6.6;

import "github.com/smartcontractkit/chainlink/evm-contracts/src/v0.6/ChainlinkClient.sol";

contract ChainlinkTimedVote is ChainlinkClient
{
  uint private oraclePayment;
  address private oracle;
  bytes32 private jobId;
  uint private yesCount;
  uint private noCount;
  bool private votingLive;
  mapping(address => bool) public voters;

  //only the contract owner should be able to start voting
  address payable owner;
  modifier onlyOwner {
  require(msg.sender == owner);
  _;
  }

  constructor() public {
      setPublicChainlinkToken();
      owner = msg.sender;
      oraclePayment = 0.1 * 10 ** 18; // 0.1 LINK
      //Kovan alarm oracle
      oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e; 
      jobId = "a7ab70d561d34eb49e9b1612fd2e044b";
      //initialize votes
      yesCount = 0;
      noCount = 0;
      votingLive = false;
  }

  function startVote(uint voteMinutes) public onlyOwner {
      Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
      req.addUint("until", now + voteMinutes * 1 minutes);
      //Start voting window then submit request to sleep for $voteMinutes
      votingLive = true;
      sendChainlinkRequestTo(oracle, req, oraclePayment);
  }

  //Callback for startVote request
  function fulfill(bytes32 _requestId) public recordChainlinkFulfillment(_requestId) {
      //$voteMinutes minutes have elapsed, stop voting
      votingLive = false;
  }

  //Increments appropriate vote counter if voting is live
  function vote(bool voteCast) public {
    require(!voters[msg.sender], "already Voted!");
    //if voting is live and address hasn't voted yet, count vote  
      if(voteCast) {yesCount++;}
      if(!voteCast) {noCount++;}
      //address has voted, mark them as such
      voters[msg.sender] = true;
   }
   
   //Outputs current vote counts
  function getVotes() public view returns (uint yesVotes, uint noVotes) {
      return(yesCount, noCount);
  }

  //Lets user know if their vote has been counted
  function haveYouVoted() public view returns (bool) {
      return voters[msg.sender];
  }
}