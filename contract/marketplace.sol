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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

import "@openzeppelin/contracts/utils/Strings.sol";

contract AgroCelo {
    // Declaring variables.
    uint internal listedSeedLength = 0;
    address internal cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    // Ceating a struct to store event details.
    struct SeedInformation {
        address payable owner;
        string seedName;
        string seedImgUrl;
        string seedDetails;
        string seedLocation;
        uint price;
        string email;
        bool isBought;
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
    mapping(uint => SeedInformation) internal listedSeeds;

    //map used to store seeds purchased.
    mapping(address => PurchasedSeedInfo[]) internal purchasedSeeds;

    // Function used to list a seed.
    function listSeed(
        string memory _seedName,
        string memory _seedImgUrl,
        string memory _seedDetails,
        string memory _seedLocation,
        uint _price,
        string memory _email
    ) public {
        listedSeeds[listedSeedLength] = SeedInformation({
            owner: payable(msg.sender),
            seedName: _seedName,
            seedImgUrl: _seedImgUrl,
            seedDetails: _seedDetails,
            seedLocation: _seedLocation,
            price: _price,
            email: _email,
            isBought: false
        });
        listedSeedLength++;
    }

    // Function used to fetch a lised seed by its id.
    function getListedSeedById(
        uint _index
    )
        public
        view
        returns (
            address payable,
            string memory,
            string memory,
            string memory,
            string memory,
            uint,
            string memory,
            bool
        )
    {
        SeedInformation storage seed = listedSeeds[_index];
        return (
            seed.owner,
            seed.seedName,
            seed.seedImgUrl,
            seed.seedDetails,
            seed.seedLocation,
            seed.price,
            seed.email,
            seed.isBought
        );
    }

    // function used to purchase a seed by another farmer.
    function buySeed(
        uint _index,
        address _owner,
        string memory _seedName,
        string memory _seedImgUrl,
        uint _price,
        string memory _email
    ) public payable {
        require(_price > 0, "Price cannot be less or equal to 0");
        require(
            listedSeeds[_index].owner != msg.sender,
            "you are already an owner of this seed"
        );
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                listedSeeds[_index].owner,
                listedSeeds[_index].price
            ),
            "Transfer failed."
        );
        storePurchasedSeeds(_owner, _seedName, _seedImgUrl, _price, _email);
        listedSeeds[_index].isBought = true;
        listedSeeds[_index].owner = payable(msg.sender);
    }

    function sellSeed(uint _index) public {
        require(
            listedSeeds[_index].owner == msg.sender,
            "you are not the owner of this seed"
        );
        listedSeeds[_index].isBought = true;
    }

    // function used to fetch seeds purchased already by you.
    function getPurchasedSeeds()
        public
        view
        returns (PurchasedSeedInfo[] memory)
    {
        return purchasedSeeds[msg.sender];
    }

    // function used to store purchase seed by a particular owner.
    function storePurchasedSeeds(
        address _owner,
        string memory _seedName,
        string memory _seedImgUrl,
        uint _price,
        string memory _email
    ) internal {
        require(_price > 0, "Price cannot be less or equal to 0");

        purchasedSeeds[msg.sender].push(
            PurchasedSeedInfo({
                purchasedFrom: _owner,
                seedName: _seedName,
                price: _price,
                email: _email,
                seedImgUrl: _seedImgUrl,
                timeStamp: block.timestamp
            })
        );
    }

    // function used to get length of lised seeds.
    function getListedSeedLength() public view returns (uint) {
        return (listedSeedLength);
    }
}
