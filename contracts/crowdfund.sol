//SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CrowdFund is Initializable {

    uint256 totalRequests;

    struct Request {
        address manager;
        uint256 deadline;
        uint256 target;
        uint256 minimumContribution;
        uint256 raised;
        uint256 contributors;

    }

    mapping(uint256 => Request) public requests;
    mapping(address => mapping(uint256 => uint256)) public contributions;


    event RequestCreated(address manager, uint256 deadline, uint256 target);

    IERC20 customToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function init(address _tokenAddress) public virtual initializer {
        customToken = IERC20(_tokenAddress);
    }

    modifier onlyManager(uint256 _id) {
        require(requests[_id].manager == msg.sender, "Only manager allowed");
        _;
    }

    // create request
    function createRequest(uint256 _deadline, uint256 _target, uint256 _minContribution) external {
        require(_deadline > block.timestamp, "Past time error");
        
        totalRequests++;

        Request storage req = requests[totalRequests];

        req.manager = msg.sender;
        req.deadline = _deadline;
        req.target = _target;
        req.minimumContribution = _minContribution;

        emit RequestCreated(msg.sender, _deadline, _target);
    }

    // fund project (One who creates request cannot contribute)
    function fund(uint256 projectId, uint256 contribution) external returns(bool) {
        Request storage req = requests[projectId];

        require(req.manager != address(0), "Project does not exist");
        require(contribution >= req.minimumContribution, "Less than minimum contribution");
        require(block.timestamp < req.deadline, "Project deadline expired");
        require(msg.sender != requests[projectId].manager, "Manager not allowed refund");

        contributions[msg.sender][projectId] = contribution;
        req.contributors++;
        req.raised += contribution;

        customToken.transferFrom(msg.sender, address(this), contribution);

        return true;
    }

    // after successful end managers can claim their total amount
    function claimForManager(uint256 projectId) external onlyManager(projectId) {
        require(requests[projectId].deadline < block.timestamp, "Project still in progress");

        uint claimableAmount = requests[projectId].raised;

        // Reset struct
        requests[projectId] = Request({
            manager: address(0),
            deadline: 0,
            target: 0,
            minimumContribution: 0,
            raised: 0,
            contributors: 0
        });

        customToken.transfer(msg.sender, claimableAmount);
    }

    // after unsuccessful end contributors can claim their share
    function claimForInvestor(uint256 projectId) external {
        require(requests[projectId].deadline < block.timestamp, "Project still in progress");
        require(msg.sender != requests[projectId].manager, "Manager not allowed refund");

        uint claimableAmount = contributions[msg.sender][projectId];
        
        require(claimableAmount != 0, "Cannot claim zero amount");

        requests[projectId].raised -= claimableAmount;

        if(requests[projectId].raised == 0) {
            requests[projectId] = Request({
                manager: address(0),
                deadline: 0,
                target: 0,
                minimumContribution: 0,
                raised: 0,
                contributors: 0
            }); 
        }

        customToken.transfer(msg.sender, claimableAmount);
    }
}