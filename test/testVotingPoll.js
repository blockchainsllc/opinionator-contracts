const VotingPoll = artifacts.require("VotingPoll");

contract("VotingPoll", async accounts => {
    it("should create a standard Poll", async () => {
        let votingInstance = await VotingPoll.deployed();
        await votingInstance.createPoll("Name1", "Description1", 0, 0, 1, true, {from: accounts[0]})
        let pollObject = await votingInstance.getPoll(0)

        assert.equal("Name1", pollObject.name, "Wrong Poll name")
        assert.equal("Description1", pollObject.description, "Wrong Description")
        assert.equal(0, pollObject.startDate, "Wrong startDate")
        assert.equal(0, pollObject.endDate, "Wrong endDate")
        assert.equal(1, pollObject.votingChoice, "Wrong votingChoice")
        assert.equal(0, pollObject.proposalIds[0], "Wrong first proposalId")
        assert.equal(1, pollObject.proposalIds[1], "Wrong second proposaId")
    })


    it("should get the correct poll amount", async () => {
        let votingInstance = await VotingPoll.deployed();
        let pollObject = await votingInstance.getPollAmount()
        assert.equal(pollObject.toNumber(), 1, "Wrong amount of polls")
    })

    it("should create a non-standard Poll", async() => {
        let votingInstance = await VotingPoll.deployed();
        await votingInstance.createPoll("Name2", "Description2", 0, 0, 1, false, {from: accounts[0]})
        let pollObject = await votingInstance.getPoll(1)

        assert.equal("Name2", pollObject.name, "Wrong Poll name")
        assert.equal("Description2", pollObject.description, "Wrong Description")
        assert.equal(0, pollObject.startDate, "Wrong startDate")
        assert.equal(0, pollObject.endDate, "Wrong endDate")
        assert.equal(1, pollObject.votingChoice, "Wrong votingChoice")
        assert.isUndefined(pollObject.proposalIds[0], "Should not have proposals")
    })

    it("should not create a poll with enddate smaller then startdate", async () => {
        let votingInstance = await VotingPoll.deployed();
        let catchedError = false
        try{
            await votingInstance.createPoll("Name3", "Description3", 2, 1, 1, false, {from: accounts[0]})
        } catch (e) {
            catchedError = true
            assert(e.toString().includes("Error: The enddate must be larger then the startdate"))
        }
        assert(catchedError)
    })

    it("should create an inactive proposal", async () => {
        let votingInstance = await VotingPoll.deployed();
        await votingInstance.createProposal("Name1", "Description1", 1, {from: accounts[1]})
        let proposalObject = await votingInstance.getProposal(2)

        assert.equal("Name1", proposalObject.name, "Wrong Poll name")
        assert.equal("Description1", proposalObject.description, "Wrong Description")
        assert.equal(accounts[1], proposalObject.author, "Wrong author")
        assert.equal(false, proposalObject.activated, "Should not be activated")
    })

    it("should not activate proposals that are not part of a poll", async () => {
        let votingInstance = await VotingPoll.deployed();
        let catchedError = false
        try{
            await votingInstance.activateProposal(2, 0, {from: accounts[0]})
        } catch (e) {
            catchedError = true
            assert(e.toString().includes("Error: This proposal is not part of that poll!"))
        }
        assert(catchedError)
    })

    it("should not create proposals as soon as the poll endet", async () => {
        let votingInstance = await VotingPoll.deployed();
        await votingInstance.createPoll("Name3", "Description3", 0, 1, 1, false, {from: accounts[0]})
        let catchedError = false
        try{
            await votingInstance.createProposal("Name1", "Description1", 2, {from: accounts[1]})
        } catch (e) {
            catchedError = true
            assert(e.toString().includes("Error: This poll is not active anymore!"))
        }
        assert(catchedError)
    })

    it("should only allow pollAuthor to activate proposals", async () => {
        let votingInstance = await VotingPoll.deployed();
        let catchedError = false
        try{
            await votingInstance.activateProposal(2, 1, {from: accounts[2]})
        } catch (e) {
            catchedError = true
            assert(e.toString().includes("You are not the poll owner"))
        }
        assert(catchedError)
    })

    it("should activate a proposal", async () => {
        let votingInstance = await VotingPoll.deployed();

        await votingInstance.activateProposal(2, 1, {from: accounts[0]})
        assert((await votingInstance.proposals(2)).activated, "The Proposal should have been activated")
    })
    
    it("should not be able to activate a proposal twice", async () => {
        let votingInstance = await VotingPoll.deployed();
        let catchedError = false
        try{
            await votingInstance.activateProposal(2, 1, {from: accounts[0]})
        } catch (e) {
            catchedError = true
            assert(e.toString().includes("Error: Proposal is already activated!"))
        }
        assert(catchedError)
    })

    it("should create an activated proposal if the poll owner creates it", async () => {
        let votingInstance = await VotingPoll.deployed();
        await votingInstance.createProposal("Name2", "Description2", 1, {from: accounts[0]})
        let proposalObject = await votingInstance.getProposal(3)

        assert.equal("Name2", proposalObject.name, "Wrong Poll name")
        assert.equal("Description2", proposalObject.description, "Wrong Description")
        assert.equal(accounts[0], proposalObject.author, "Wrong author")
        assert.equal(true, proposalObject.activated, "Should not be activated")
    })

    it("should get the correct proposal ID's from a poll", async () => {
        let votingInstance = await VotingPoll.deployed();
        let proposalArray = await votingInstance.getProposalsFromPoll(0);
        assert.equal(proposalArray.length, 2, "Wrong length")
    })
    
    it("should fail to create a proposal for a standard poll", async () => {
        let votingInstance = await VotingPoll.deployed();
        let catchedError = false
        try{
            catchedError = true
            await votingInstance.createProposal("Name1", "Description1", 0, {from: accounts[1]})
        } catch(e) {
            assert(e.toString().includes("Error: You can not add proposals to standard polls!"))
        }
        assert(catchedError)
    })


})