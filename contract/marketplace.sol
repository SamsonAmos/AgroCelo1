
// SPDX-License-Identifier: GPL-3.0




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
        address  owner;
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

    // Event to log the seed listing
    event SeedListed(string seedName, uint price, address owner);

    // Event to log the seed purchase
    event SeedPurchased(string seedName, uint price, address buyer, address seller);

    //map used to store listed seeds.
    mapping (uint => SeedInformation) internal listedSeeds;

    //map used to store seeds purchased.
    mapping(address => PurchasedSeedInfo[]) internal purchasedSeeds;

    mapping (string => uint) public seedNames;

    // Function used to list a seed.
   function listSeed(string memory _seedName, string memory _seedImgUrl,
    string memory _seedDetails, string memory  _seedLocation, uint _price, string memory _email) public {
        
        require(seedNames[_seedName] == 0, "Seed with this name already exists");
        // Validate that seedName is not empty
        require(bytes(_seedName).length > 0, "seedName cannot be empty");
        // Validate that seedImgUrl is not empty
        require(bytes(_seedImgUrl).length > 0, "seedImgUrl cannot be empty");

        require(bytes(_seedName).length <= 32, "Seed name must be at most 32 bytes");
        
        require(bytes(_seedImgUrl).length <= 64, "Seed image URL must be at most 64 bytes");
 
        require(bytes(_seedDetails).length <= 256, "Seed details must be at most 256 bytes");
 
        require(bytes(_seedLocation).length <= 64, "Seed location must be at most 64 bytes");
 
        require(bytes(_email).length <= 32, "Email must be at most 32 bytes");


        listedSeeds[listedSeedLength] = SeedInformation({
        owner : payable(msg.sender),
        seedName: _seedName,
        seedImgUrl: _seedImgUrl,
        seedDetails : _seedDetails,
        seedLocation: _seedLocation,
        price : _price,
        email : _email
      });
     listedSeedLength++;

     emit SeedListed(_seedName, _price, msg.sender);

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

        return (
            listedSeeds[_index].owner,
            listedSeeds[_index].seedName,
            listedSeeds[_index].seedImgUrl,
            listedSeeds[_index].seedDetails,
            listedSeeds[_index].seedLocation,
            listedSeeds[_index].price,
            listedSeeds[_index].email
        );
    }


// function used to purchase a seed by another farmer.
function buySeed(uint _index, address _owner, string memory _seedName, string memory _seedImgUrl, uint _price, string memory _email) public payable {
    // Validate that the seed exists
    require(_index < listedSeedLength, "Seed not found");
    // Validate that the caller is not the owner of the seed
    require(listedSeeds[_index].owner != msg.sender, "You are already the owner of this seed");
    // Validate that the price of the seed matches the input price
    require(listedSeeds[_index].price == _price, "Incorrect seed price");
    // Validate that the caller has enough balance in cUSDT token
    require(IERC20Token(cUsdTokenAddress).balanceOf(msg.sender) >= listedSeeds[_index].price, "Insufficient balance in cUSDT token");
    // Transfer the cUSDT token from the caller to the seed owner
    require(
        IERC20Token(cUsdTokenAddress).transfer(listedSeeds[_index].owner, listedSeeds[_index].price),
        "Transfer of cUSDT token failed"
    );
    // Store the purchased seed information for the caller
    storePurchasedSeeds(_owner, _seedName, _seedImgUrl, _price, _email);

    emit SeedPurchased(listedSeeds[_index].seedName, listedSeeds[_index].price, msg.sender, listedSeeds[_index].owner);

}

// function used to fetch seeds purchased already by you.
function getPurchasedSeeds() public view returns (PurchasedSeedInfo[] memory) {
    return purchasedSeeds[msg.sender];
}


// function used to store purchase seed by a particular owner.
function storePurchasedSeeds(address _owner,
 string memory _seedName, string memory _seedImgUrl, uint _price, string memory _email) public {
    purchasedSeeds[msg.sender].push(PurchasedSeedInfo({purchasedFrom : _owner,
    seedName : _seedName, price : _price, email : _email, seedImgUrl : _seedImgUrl, timeStamp : block.timestamp }));
}



// function used to get length of lised seeds.
    function getListedSeedLength() public view returns (uint) {
        return (listedSeedLength);
    }

}
