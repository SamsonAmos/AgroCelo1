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
        address  owner;
        string seedName;
        string seedImgUrl;
        string seedDetails;
        string  seedLocation;
        uint price;
    }

    struct PurchasedSeedInfo {
        address purchasedFrom;
        string seedName;
        string seedImgUrl;
        uint256 timeStamp;
        uint price;
    }

    //map used to store listed seeds.
    mapping (uint => SeedInformation) internal listedSeeds;

    //map used to store seeds purchased.
    mapping(address => PurchasedSeedInfo[]) internal purchasedSeeds;


    // Function used to list a seed.
    function listSeed(string memory _seedName, string memory _seedImgUrl,
    string memory _seedDetails, string memory  _seedLocation, uint _price) public {
        listedSeeds[listedSeedLength] = SeedInformation({
        owner : payable(msg.sender),
        seedName: _seedName,
        seedImgUrl: _seedImgUrl,
        seedDetails : _seedDetails,
        seedLocation: _seedLocation,
        price : _price
      });
     listedSeedLength++;
}


// Function used to fetch a lised seed by its id.
    function getListedSeedById(uint _index) public view returns (
        address,
        string memory,
        string memory,
        string memory,
        string memory,
        uint price

    ) {

        return (
            listedSeeds[_index].owner,
            listedSeeds[_index].seedName,
            listedSeeds[_index].seedImgUrl,
            listedSeeds[_index].seedDetails,
            listedSeeds[_index].seedLocation,
            listedSeeds[_index].price
        );
    }


// function used to purchase a seed.
function buySeed(uint _index, string memory _seedName, string memory _seedImgUrl,  uint _price) public payable  {
        require(listedSeeds[_index].owner != msg.sender, "you are already an owner of this seed");
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            listedSeeds[_index].owner,
            listedSeeds[_index].price
          ),
          "Transfer failed."
        );
        storePurchasedSeeds(msg.sender, _seedName, _seedImgUrl, _price);
    }

// function used to fetch seeds purchased already.
function getPurchasedSeeds() public view returns (PurchasedSeedInfo[] memory) {
    return purchasedSeeds[msg.sender];
}


// function used to store purchase seed by a particular owner.
function storePurchasedSeeds(address _owner,
 string memory _seedName, string memory _seedImgUrl, uint _price) public {
    purchasedSeeds[msg.sender].push(PurchasedSeedInfo({purchasedFrom : _owner,
    seedName : _seedName, price : _price, seedImgUrl : _seedImgUrl, timeStamp : block.timestamp }));
}



// function used to get length of lised seeds.
    function getListedSeedLength() public view returns (uint) {
        return (listedSeedLength);
    }

}
