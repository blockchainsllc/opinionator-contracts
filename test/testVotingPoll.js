const VotingPoll = artifacts.require("VotingPoll");

contract("VotingPoll", async accounts => {
    it("should create a standard Poll", async () => {
        let votingInstance = await VotingPoll.deployed();
        votingInstance.createPoll("Name1", "Description1", 0, 0, 1, true, {from: accounts[0]})
        let pollObject = await votingInstance.getPoll(0)

        assert.equal("Name1", pollObject.name, "Wrong Poll name")
        assert.equal("Description1", pollObject.description, "Wrong Description")
        assert.equal(0, pollObject.startDate, "Wrong startDate")
        assert.equal(0, pollObject.endDate, "Wrong endDate")
        assert.equal(1, pollObject.votingChoice, "Wrong votingChoice")
        assert.equal(0, pollObject.proposalIds[0], "Wrong first proposalId")
        assert.equal(1, pollObject.proposalIds[1], "Wrong second proposaId")
    })

    it("should create a non-standard Poll", async() => {
        let votingInstance = await VotingPoll.deployed();
        votingInstance.createPoll("Name2", "Description2", 0, 0, 1, false, {from: accounts[0]})
        let pollObject = await votingInstance.getPoll(1)

        assert.equal("Name2", pollObject.name, "Wrong Poll name")
        assert.equal("Description2", pollObject.description, "Wrong Description")
        assert.equal(0, pollObject.startDate, "Wrong startDate")
        assert.equal(0, pollObject.endDate, "Wrong endDate")
        assert.equal(1, pollObject.votingChoice, "Wrong votingChoice")
        assert.isUndefined(pollObject.proposalIds[0], "Should not have proposals")
    })

    it("should create an inactive proposal", async () => {
        let votingInstance = await VotingPoll.deployed();
        votingInstance.createProposal("Name1", "Description1", 1, {from: accounts[1]})
        let proposalObject = await votingInstance.getProposal(2)

        assert.equal("Name1", proposalObject.name, "Wrong Poll name")
        assert.equal("Description1", proposalObject.description, "Wrong Description")
        assert.equal(accounts[1], proposalObject.author, "Wrong author")
        assert.equal(false, proposalObject.activated, "Should not be activated")
    })

    it("should only allow pollAuthor to activate proposals", async () => {
        let votingInstance = await VotingPoll.deployed();
        try{
            await votingInstance.activateProposal(2, 1, {from: accounts[2]})
        } catch (e) {
            assert(e.toString().includes("You are not the poll owner"))
        }
    })

    it("should activate a proposal")
    it("should fail to create a proposal for a standard poll")
    it("should do something boring with my life what the futch")
})