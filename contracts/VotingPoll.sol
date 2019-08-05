pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

///@dev the polls could be spamed with proposals to reduce iteration speed

contract VotingPoll {

    struct Poll {
        string name;
        string description;
        uint[] proposalIds;
        address author;
        bool allowProposalUpdate;
        uint startDate;
        uint endDate; ///@dev if 0 then open end
        VotingChoice votingChoice;
        bool standardPoll;
    }

    struct Proposal {
        string name;
        string description;
        address author;
        uint pollId;
        bool activated;
    }

    enum VotingChoice {useNewestVote, useOldestVote, nullifyAllOnDoubleVote}

    ///@notice contains all proposals
    Poll[] public polls;

    ///@notice contains all proposals
    Proposal[] public proposals;

    ///@notice creates a Poll
    ///@param _name Name of the poll
    ///@param _description A subtle description of the poll
    ///@param _startDate the start date of the proposal
    ///@param _endDate the endDate of the proposal (0 for no end date)
    ///@param _votingChoice How double votes should be counted
    ///@param _standardPoll If true, yes and no proposal will be created and further proposal creation prohibited
    function createPoll(string memory _name, string memory _description, uint _startDate, uint _endDate, VotingChoice _votingChoice, bool _standardPoll) public {
        Poll memory newPoll;
        newPoll.name = _name;
        newPoll.description = _description;
        newPoll.author = msg.sender;
        newPoll.startDate = _startDate;
        newPoll.endDate = _endDate;
        newPoll.votingChoice = _votingChoice;
        newPoll.standardPoll = _standardPoll;
        polls.push(newPoll);

        if(_standardPoll){
            createProposalInternal("Yes", "", polls.length - 1, true);
            createProposalInternal("No", "", polls.length - 1, true);
        }

        emit LogCreatePoll(polls.length - 1, msg.sender);
    }

    ///@notice creates a proposal and saves it seperated in a map
    ///@param _proposalName The name of the proposal
    ///@param _proposalDescription The high level description of the proposal
    ///@param _pollId The id of the proposal which it is part of
    ///@param _activated true if created by poll author, else its false and needs to be activated by poll author
    function createProposalInternal(string memory _proposalName, string memory _proposalDescription, uint _pollId, bool _activated) internal {

        Proposal memory newProposal;
        newProposal.name = _proposalName;
        newProposal.description = _proposalDescription;
        newProposal.author = msg.sender;
        newProposal.pollId = _pollId;
        newProposal.activated = _activated;
        proposals.push(newProposal);
        polls[_pollId].proposalIds.push(proposals.length - 1 );
        emit LogCreateProposal(proposals.length - 1, msg.sender, _pollId);
    }

    ///@notice creates a proposal and saves it seperated in a map
    ///@param _proposalName The name of the proposal
    ///@param _proposalDescription The high level description of the proposal
    ///@param _pollId The id of the proposal which it is part of
    function createProposal(string memory _proposalName, string memory _proposalDescription, uint _pollId) public isStillActive(_pollId) {
        require(!polls[_pollId].standardPoll, "Error: You can not add proposals to standart polls!");
        if(polls[_pollId].author == msg.sender)
            createProposalInternal(_proposalName,  _proposalDescription, _pollId, true);
        else
            createProposalInternal(_proposalName,  _proposalDescription, _pollId, false);
    }

    ///@notice adds a proposal to a poll
    ///@param _proposalId The proposalId to activate
    ///@param _pollId The id of the proposal
    function activateProposal(uint _proposalId, uint _pollId) public onlyPollAuthor(_pollId) isStillActive(_pollId) {
        ///@dev issues with 0?
        require(proposals[_proposalId].pollId == _pollId, "Error: This proposal is not part of that poll!");
        require(!proposals[_proposalId].activated, "Error: Proposal is already activated!");
        proposals[_proposalId].activated = true;

        emit LogProposalActivated(_pollId, _proposalId, proposals[_proposalId].author);
    }

    ///@notice returns an array with the proposal ids for a specific poll
    ///@param _pollId The id of the poll that is to be searched
    function getProposalsFromPoll(uint _pollId) public view returns (uint[] memory) {
        return polls[_pollId].proposalIds;
    }

    ///@notice returns a poll with the given id
    ///@param _pollId The id of the poll requested
    function getPoll(uint _pollId) public view returns(Poll memory) {
        return polls[_pollId];
    }

    ///@notice returns the amount of polls stored in this contract
    function getPollAmount() public view returns(uint) {
        return polls.length;
    }

    ///@notice return all values from proposal
    ///@param _proposalId The Id of the searched proposal
    function getProposal(uint _proposalId) public view returns(string memory, string memory, address, uint) {
        return (proposals[_proposalId].name, proposals[_proposalId].description, proposals[_proposalId].author, proposals[_proposalId].pollId);
    }

    modifier onlyPollAuthor(uint pollId) {
        require(msg.sender == polls[pollId].author, "Error: You are not the poll owner!");
        _;
    }

    modifier onlyProposalAuthor(uint proposalId) {
        require(msg.sender == proposals[proposalId].author, "Error: You are not the proposal owner!");
        _;
    }

    modifier isStillActive(uint _pollId) {
        require(polls[_pollId].endDate > block.timestamp || polls[_pollId].endDate == 0, "Error: This poll is not active anymore!");
        _;
    }

    event LogCreateProposal(uint proposalId, address proposalAuthor, uint pollId);

    event LogCreatePoll(uint pollId, address pollAuthor);

    event LogProposalActivated(uint pollId, uint proposalId, address proposalAuthor);

}