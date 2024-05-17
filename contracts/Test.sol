// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Solver.sol";

contract Test {
    EthDomainResolver public domainResolver;

    constructor(address _resolverAddress) {
        domainResolver = new EthDomainResolver(_resolverAddress);
    }

    struct News {
        string title;
        string description;
        string link;
        address publisher;
        string publisherName;
        string publisherDomain;
        uint256 timestamp;
        int256 votes; // New field to store votes
    }

    struct Profile {
        string name;
        string ethDomain; // whit ens protocol
        string web2Page;
        int256 reputation; // not used for now
    }

    mapping(uint256 => News) public newsRegistry;
    mapping(address => uint256) public credits;
    mapping(address => uint256) public lastSubmission;
    mapping(address => Profile) public profiles;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // Tracks if an address has voted on a specific news item

    uint256 public newsCount;
    uint256 public dailyLimit = 1;

    function submitNews(
        string memory _title,
        string memory _description,
        string memory _link
    ) public {
        // Check if the user is new and initialize credits if they are
        if (credits[msg.sender] == 0 && lastSubmission[msg.sender] == 0) {
            credits[msg.sender] = 5;
        }

        require(credits[msg.sender] > 0, "Insufficient credits");
        // require(block.timestamp - lastSubmission[msg.sender] > 1 days, "Daily submission limit reached");

        // ensResolve(profiles[msg.sender].ethDomain) == profiles[msg.sender]
        require(
            domainResolver.resolveAddressFromDomain(profiles[msg.sender].ethDomain) ==
                msg.sender,
            "Invalid ENS domain"
        );

        newsRegistry[newsCount] = News({
            title: _title,
            description: _description,
            link: _link,
            publisher: msg.sender, // msg.sender -> address of the publisher this using ens to get the address of the publisher
            publisherName: profiles[msg.sender].name,
            publisherDomain: profiles[msg.sender].ethDomain,
            timestamp: block.timestamp,
            votes: 0 // Initialize votes to 0
        });

        lastSubmission[msg.sender] = block.timestamp;
        credits[msg.sender] -= 1;
        newsCount += 1;
    }

    function buyCredits(uint256 amount) public payable {
        // Implement credit purchasing logic
        credits[msg.sender] += amount;
    }

    function voteNews(uint256 newsId, int256 vote) public {
        // vote is -1 or 1
        require(newsId < newsCount, "Invalid news ID");
        require(!hasVoted[newsId][msg.sender], "Already voted");
        require(vote == 1 || vote == -1, "Invalid vote value");

        newsRegistry[newsId].votes += vote;
        hasVoted[newsId][msg.sender] = true;
    }

    // function getMostImportantNews() public view returns (News memory) {
    //     uint256 maxVotes = 0;
    //     uint256 mostImportantNewsId = 0;

    //     for (uint256 i = 0; i < newsCount; i++) {
    //         if (newsRegistry[i].votes > maxVotes) {
    //             maxVotes = newsRegistry[i].votes;
    //             mostImportantNewsId = i;
    //         }
    //     }

    //     return newsRegistry[mostImportantNewsId];
    // }

    function getTop10News()
        public
        view
        returns (News[] memory, uint256[] memory)
    {
        News[] memory sortedNews = new News[](newsCount);
        uint256[] memory sortedNewsIds = new uint256[](newsCount);

        // Copy news items and their IDs to temporary arrays for sorting
        for (uint256 i = 0; i < newsCount; i++) {
            sortedNews[i] = newsRegistry[i];
            sortedNewsIds[i] = i;
        }

        // Sort news by votes using a simple bubble sort
        for (uint256 i = 0; i < newsCount - 1; i++) {
            for (uint256 j = 0; j < newsCount - i - 1; j++) {
                if (sortedNews[j].votes < sortedNews[j + 1].votes) {
                    // Swap news items
                    News memory tempNews = sortedNews[j];
                    sortedNews[j] = sortedNews[j + 1];
                    sortedNews[j + 1] = tempNews;

                    // Swap their IDs
                    uint256 tempId = sortedNewsIds[j];
                    sortedNewsIds[j] = sortedNewsIds[j + 1];
                    sortedNewsIds[j + 1] = tempId;
                }
            }
        }

        // Create arrays for the top 10 news items and their IDs
        uint256 topCount = newsCount < 10 ? newsCount : 10;
        News[] memory top10News = new News[](topCount);
        uint256[] memory top10NewsIds = new uint256[](topCount);

        for (uint256 i = 0; i < topCount; i++) {
            top10News[i] = sortedNews[i];
            top10NewsIds[i] = sortedNewsIds[i];
        }

        return (top10News, top10NewsIds);
    }
}
