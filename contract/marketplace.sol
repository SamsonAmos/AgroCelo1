// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

import "@openzeppelin/contracts/utils/Strings.sol";

contract AgroCelo{
   // Declaring variables.
    uint internal listedSeedLength = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    // Ceating a struct to store event details.
    struct SeedInformation {
        address payable  owner;
        string seedName;
        string seedImgUrl;
        string seedDetails;
        string  seedLocation;
        uint price;
        string email;
    }

    struct PurchasedSeedInfo {
        address purchasedFrom;
        string seedName;
        string seedImgUrl;
        uint256 timeStamp;
        uint price;
        string email;
    }

    //map used to store listed seeds.
    mapping (uint => SeedInformation) internal listedSeeds;

    //map used to store seeds purchased.
    mapping(address => PurchasedSeedInfo[]) internal purchasedSeeds;


    // Function used to list a seed.
    function listSeed(
        string calldata _seedName, 
        string calldata _seedImgUrl,
        string calldata _seedDetails,
        string calldata  _seedLocation, 
        uint _price, 
        string calldata _email
        ) public {


        require(bytes(_seedName).length > 0, "Input is invalid");
        require(bytes(_seedImgUrl).length > 0, "Input is invalid");
        require(bytes(_seedDetails).length > 0, "Input is invalid");
        require(bytes(_seedLocation).length > 0, "Input is invalid");
        require(bytes(_email).length > 0, "Input is invalid");



        listedSeeds[listedSeedLength] = SeedInformation(
        payable(msg.sender),
         _seedName,
        _seedImgUrl,
         _seedDetails,
         _seedLocation,
        _price,
         _email
      );
     listedSeedLength++;
}


// Function used to fetch a lised seed by its id.
    function getListedSeedById(uint _index) public view returns (
        address,
        string memory,
        string memory,
        string memory,
        string memory,
        uint price,
        string memory

    ) {

        SeedInformation memory _seed = listedSeeds[_index];

        return (
            _seed.owner,
            _seed.seedName,
            _seed.seedImgUrl,
            _seed.seedDetails,
            _seed.seedLocation,
            _seed.price,
            _seed.email
        );
    }


// function used to purchase a seed by another farmer.
function buySeed(
    uint _index, 
    address _owner, 
    string calldata _seedName, 
    string calldata _seedImgUrl,  
    uint _price, 
    string calldata _email

    ) public payable  {

        SeedInformation memory _seed = listedSeeds[_index];


        require(_seed.owner != msg.sender, "you are already an owner of this seed");
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            _seed.owner,
            _seed.price
          ),
          "Transfer failed."
        );
        storePurchasedSeeds(_owner, _seedName, _seedImgUrl, _price, _email);
    }

// function used to fetch seeds purchased already by you.
function getPurchasedSeeds() public view returns (PurchasedSeedInfo[] memory) {
    return purchasedSeeds[msg.sender];
}


// function used to store purchase seed by a particular owner.
function storePurchasedSeeds(
    address _owner,
    string calldata _seedName, 
    string calldata _seedImgUrl, 
    uint _price, 
    string calldata _email
    ) public {

    purchasedSeeds[msg.sender].push(PurchasedSeedInfo({purchasedFrom : _owner,
    seedName : _seedName, price : _price, email : _email, seedImgUrl : _seedImgUrl, timeStamp : block.timestamp }));
}



// function used to get length of lised seeds.
    function getListedSeedLength() public view returns (uint) {
        return (listedSeedLength);
    }


     //function to delete a seed
    function deleteSeed(uint _index) public{
        require(listedSeeds[_index].owner == msg.sender, "You are not the owner of the seeds");
        delete listedSeeds[_index];
        
    }




}
