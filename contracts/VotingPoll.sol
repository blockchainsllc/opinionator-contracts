pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;

///@dev the polls could be spamed with proposals to reduce iteration speed

contract VotingPoll {

    struct Poll {
        string name;
        string description;
        uint[] proposalIds;
        address author;
        bool allowProposalUpdate;
        bool standardPoll;
        uint startDate;
        uint endDate; ///@dev if 0 then open end
        VotingChoice votingChoice;
    }

    struct Proposal {
        string name;
        string description;
        address author;
        bool activated;
        uint pollId;
    }

    enum VotingChoice {useNewestVote, useOldestVote, nullifyAllOnDoubleVote}

    ///@notice contains all polls
    Poll[] public polls;

    ///@notice contains all proposals
    Proposal[] public proposals;

    event LogCreateProposal(uint indexed proposalId, address indexed proposalAuthor, uint indexed pollId);

    event LogCreatePoll(uint indexed pollId, address indexed pollAuthor);

    event LogProposalActivated(uint indexed pollId, uint indexed proposalId, address indexed proposalAuthor);

    ///@notice creates a Poll
    ///@param _name name of the poll
    ///@param _description a subtle description of the poll
    ///@param _startDate the start date of the proposal
    ///@param _endDate the end date of the proposal (0 for no end date)
    ///@param _votingChoice how double votes should be counted
    ///@param _standardPoll if true, yes and no proposal will be created and further proposal creation prohibited
    function createPoll(
        string calldata _name,
        string calldata _description,
        uint _startDate,
        uint _endDate,
        VotingChoice _votingChoice,
        bool _standardPoll
    ) external {
        require(_endDate == 0 || _endDate > _startDate, "Error: The enddate must be larger then the startdate");
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

    ///@notice creates a proposal and saves it seperated in an array
    ///@param _proposalName the name of the proposal
    ///@param _proposalDescription the high level description of the proposal
    ///@param _pollId the id of the proposal which it is part of
    function createProposal(
        string calldata _proposalName,
        string calldata _proposalDescription,
        uint _pollId
    )
        external
        isStillActive(_pollId)
    {
        require(!polls[_pollId].standardPoll, "Error: You can not add proposals to standard polls!");
        if(polls[_pollId].author == msg.sender)
            createProposalInternal(_proposalName,  _proposalDescription, _pollId, true);
        else
            createProposalInternal(_proposalName,  _proposalDescription, _pollId, false);
    }

    ///@notice creates a proposal and saves it seperated in a map
    ///@param _proposalName the name of the proposal
    ///@param _proposalDescription The high level description of the proposal
    ///@param _pollId the id of the proposal which it is part of
    ///@param _activated true if created by poll author, else its false and needs to be activated by poll author
    function createProposalInternal(
        string memory _proposalName,
        string memory _proposalDescription,
        uint _pollId,
        bool _activated
    ) internal {

        Proposal memory newProposal;
        newProposal.name = _proposalName;
        newProposal.description = _proposalDescription;
        newProposal.author = msg.sender;
        newProposal.pollId = _pollId;
        newProposal.activated = _activated;
        proposals.push(newProposal);
        polls[_pollId].proposalIds.push(proposals.length - 1);
        emit LogCreateProposal(proposals.length - 1, msg.sender, _pollId);
    }

    ///@notice activates an already created proposal
    ///@param _proposalId the proposalId to activate
    ///@param _pollId the id of the proposal
    function activateProposal(
        uint _proposalId,
        uint _pollId
    )
        external
        onlyPollAuthor(_pollId)
        isStillActive(_pollId)
    {
        require(proposals[_proposalId].pollId == _pollId, "Error: This proposal is not part of that poll!");
        require(!proposals[_proposalId].activated, "Error: Proposal is already activated!");
        proposals[_proposalId].activated = true;

        emit LogProposalActivated(_pollId, _proposalId, proposals[_proposalId].author);
    }

    ///@notice returns a poll with the given id
    ///@param _pollId the id of the poll requested
    ///@return poll
    function getPoll(uint _pollId) external view returns(Poll memory) {
        return polls[_pollId];
    }

    ///@notice returns the amount of polls stored in this contract
    ///@return returns the amount of polls stored in this contract
    function getPollAmount() external view returns(uint) {
        return polls.length;
    }

    ///@notice return all values from proposal
    ///@param _proposalId the Id of the searched proposal
    ///@return the proposal with the given id as single values
    function getProposal(
        uint _proposalId
    )
        external
        view
        returns(
            string memory,
            string memory,
            address,
            uint
        )
    {
        return (proposals[_proposalId].name, proposals[_proposalId].description, proposals[_proposalId].author, proposals[_proposalId].pollId);
    }

    ///@notice returns an array with the proposal ids for a specific poll
    ///@param _pollId the id of the poll that is to be searched
    ///@return array with proposal ids
    function getProposalsFromPoll(uint _pollId) external view returns (uint[] memory) {
        return polls[_pollId].proposalIds;
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
}