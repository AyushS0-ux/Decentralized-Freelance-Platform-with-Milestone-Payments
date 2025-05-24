// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Freelance Platform with Milestone Payments
 */
contract FreelancePlatform {
    enum ProjectStatus { Created, InProgress, Completed, Cancelled }

    struct Milestone {
        string description;
        uint256 amount;
        bool paid;
    }

    struct Project {
        address client;
        address freelancer;
        ProjectStatus status;
        uint256 totalAmount;
        uint256 milestonesCount;
        mapping(uint256 => Milestone) milestones;
    }

    uint256 public projectCount;
    mapping(uint256 => Project) public projects;

    event ProjectCreated(uint256 indexed projectId, address indexed client, address indexed freelancer, uint256 totalAmount);
    event MilestoneReleased(uint256 indexed projectId, uint256 indexed milestoneId, address freelancer, uint256 amount);
    event ProjectCancelled(uint256 indexed projectId);

    modifier onlyClient(uint256 _projectId) {
        require(msg.sender == projects[_projectId].client, "Not project client");
        _;
    }

    modifier onlyFreelancer(uint256 _projectId) {
        require(msg.sender == projects[_projectId].freelancer, "Not project freelancer");
        _;
    }

    function createProject(
        address _freelancer,
        uint256 _totalAmount,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneAmounts
    ) external payable {
        require(_freelancer != address(0), "Invalid freelancer");
        require(_totalAmount == msg.value, "Incorrect value sent");
        require(_milestoneDescriptions.length == _milestoneAmounts.length, "Mismatched milestone data");

        projectCount++;
        Project storage p = projects[projectCount];
        p.client = msg.sender;
        p.freelancer = _freelancer;
        p.status = ProjectStatus.Created;
        p.totalAmount = _totalAmount;
        p.milestonesCount = _milestoneDescriptions.length;

        for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            p.milestones[i] = Milestone({
                description: _milestoneDescriptions[i],
                amount: _milestoneAmounts[i],
                paid: false
            });
        }

        emit ProjectCreated(projectCount, msg.sender, _freelancer, _totalAmount);
    }

    function releaseMilestone(uint256 _projectId, uint256 _milestoneId) external onlyClient(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status != ProjectStatus.Cancelled, "Project cancelled");
        Milestone storage m = p.milestones[_milestoneId];
        require(!m.paid, "Milestone already paid");

        m.paid = true;
        payable(p.freelancer).transfer(m.amount);

        emit MilestoneReleased(_projectId, _milestoneId, p.freelancer, m.amount);
    }

    function cancelProject(uint256 _projectId) external onlyClient(_projectId) {
        Project storage p = projects[_projectId];
        require(p.status == ProjectStatus.Created || p.status == ProjectStatus.InProgress, "Cannot cancel");

        p.status = ProjectStatus.Cancelled;

        // Refund unpaid milestones
        uint256 refundAmount = 0;
        for (uint256 i = 0; i < p.milestonesCount; i++) {
            if (!p.milestones[i].paid) {
                refundAmount += p.milestones[i].amount;
            }
        }

        if (refundAmount > 0) {
            payable(p.client).transfer(refundAmount);
        }

        emit ProjectCancelled(_projectId);
    }
}
