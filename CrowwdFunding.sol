// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CrowdFunding {
    //admin
    address payable public admin;
    //funds receiver
    address payable public wallet;
    // Default token for transactions
    ERC20 public enscToken;

    constructor ( ERC20 _enscToken,  address _wallet ) {
        enscToken = _enscToken;
        admin = payable(msg.sender);
        wallet = payable(_wallet);
    }

    modifier onlyOwner ( ) {
        require(msg.sender == admin, "only this contract deployer can invoke this function");
        _;
    }
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;

    function createCampaign(
        address _owner, 
        string memory _title, 
        string memory _description, 
        uint256 _target, 
        uint256 _deadline, 
        string memory _image
        ) public onlyOwner returns (uint256) {
        Campaign storage campaign = campaigns[numberOfCampaigns];

        require(campaign.deadline < block.timestamp, "The deadline should be a date in the future.");

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.image = _image;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(uint256 _id, uint256 _amount) public payable {
        uint256 amount = _amount;
        require( amount > 0, "you can't donate zero");
        require(enscToken.allowance(msg.sender, address(this)) >= amount,
         "Insufficent allowance for this contract to spend user ENSC balance");
        require(enscToken.balanceOf(msg.sender) >= amount,
         "User doesn't have enough ENSC Tokens to spend" ); 
        Campaign storage campaign = campaigns[_id];
         require(campaign.deadline <= block.timestamp, " donation duration is over!");
        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        bool sent = enscToken.transferFrom(msg.sender, wallet, amount);
        require(sent, "Failed to transfer ENSC Token from user to contract");
        campaign.amountCollected = campaign.amountCollected + amount;

    }

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](numberOfCampaigns);

        for(uint i = 0; i < numberOfCampaigns; i++) {
            Campaign storage item = campaigns[i];

            allCampaigns[i] = item;
        }

        return allCampaigns;
    }
}