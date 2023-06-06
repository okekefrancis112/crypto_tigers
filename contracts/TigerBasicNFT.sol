// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/*
   NFT Contract along the lines of CryptoPunks. For the original see:
   https://github.com/larvalabs/cryptopunks/blob/master/contracts/CryptoPunksMarket.sol

   Incorporates some ideas and code from the OpenZeppelin ERC721Enumerable contract:

   https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol
   https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#ERC721Enumerable
*/
contract TigerBasicNFT {
    // how many unique tiger tokens exist
    uint256 public constant totalSupply = 100;

    // address that deployed this contract
    address private deployer;

    address constant ZEROADDRESS = address(0);

    // address of the artist, initial owner of all tiger tokens, recipient of artist's fees
    address private artist;

    // initial sale price for all tokens
    uint256 private startingPrice;

    // artist fee percentage
    uint256 public artistFeePercentage = 5;

    // service fee percentage
    uint256 public serviceFeePercentage = 1;

    uint256 public royalty;
    uint256 public charges;

    // mapping from token ID to owner address
    mapping(uint256 => address) private tigerOwners;

    // mapping from owner address to number of tokens they own
    mapping(address => uint256) private balanceOf;
    mapping(address => uint256) public balanceRoyaltyFee;
    mapping(address => uint256) public balanceServiceFee;

    // mapping from owner address to list of IDs of all tokens they own
    mapping(address => mapping(uint256 => uint256)) private tigersOwnedBy;

    // mapping from token ID to its index position in the owner's tokens list
    mapping(uint256 => uint256) private tigersOwnedByIndex;

    // tigers currently up for sale
    struct SaleOffer {
        bool isForSale;
        address seller;
        uint256 price;
    }

    mapping(uint256 => SaleOffer) public tigersForSale;

    // ether held by the contract on behalf of addresses that have interacted with it
    mapping(address => uint256) public pendingWithdrawals;

    event TigerForSale(address indexed seller, uint256 indexed tigerId, uint256 price);
    event TigerSold(address indexed seller, address indexed buyer, uint256 indexed tigerId, uint256 price);
    event TigerWithdrawnFromSale(address indexed seller, uint256 indexed tigerId);
    event FundsWithdrawn(address indexed caller, uint256 indexed amount);

    // create the contract, artist is set here and never changes subsequently
    constructor(address _artist, uint256 _startingPrice) {
        require(_artist != address(0));
        artist = _artist;
        startingPrice = _startingPrice;
        deployer = msg.sender;
    }

    // allow anyone to see if a tiger is for sale and, if so, for how much
    function isForSale(uint256 tigerId) external view returns (bool, uint256) {
        require(tigerId < totalSupply, "index out of range");
        SaleOffer memory saleOffer = getSaleInfo(tigerId);
        if (saleOffer.isForSale) {
            return (true, saleOffer.price);
        }
        return (false, 0);
    }

    // tokens which have never been sold are for sale at the starting price,
    // all others are not unless the owner puts them up for sale
    function getSaleInfo(uint256 tigerId) private view returns (SaleOffer memory saleOffer) {
        if (tigerOwners[tigerId] == ZEROADDRESS) {
            saleOffer = SaleOffer(true, artist, startingPrice);
        } else {
            saleOffer = tigersForSale[tigerId];
        }
    }

    // get the number of tigers owned by the address
    function getBalance(address owner) public view returns (uint256) {
        return balanceOf[owner];
    }

    // get the current owner of a token, unsold tokens belong to the artist
    function getOwner(uint256 tigerId) public view returns (address) {
        require(tigerId < totalSupply, "index out of range");
        address owner = tigerOwners[tigerId];
        if (owner == ZEROADDRESS) {
            owner = artist;
        }
        return owner;
    }

    // get the ID of the index'th tiger belonging to owner (who must own at least index + 1 tigers)
    function tigerByOwnerAndIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf[owner], "owner doesn't have that many tigers");
        return tigersOwnedBy[owner][index];
    }

    // allow the current owner to put a tiger token up for sale
    function putUpForSale(uint256 tigerId, uint256 minSalePriceInWei) external {
        require(tigerId < totalSupply, "index out of range");
        require(getOwner(tigerId) == msg.sender, "not owner");
        tigersForSale[tigerId] = SaleOffer(true, msg.sender, minSalePriceInWei);
        emit TigerForSale(msg.sender, tigerId, minSalePriceInWei);
    }

    // allow the current owner to withdraw a tiger token from sale
    function withdrawFromSale(uint256 tigerId) external {
        require(tigerId < totalSupply, "index out of range");
        require(getOwner(tigerId) == msg.sender, "not owner");
        tigersForSale[tigerId] = SaleOffer(false, ZEROADDRESS, 0);
        emit TigerWithdrawnFromSale(msg.sender, tigerId);
    }

    // update ownership tracking for newly acquired tiger token
    function updateTigerOwnership(uint256 tigerId, address newOwner, address previousOwner) private {
        bool firstSale = tigerOwners[tigerId] == address(0);
        tigerOwners[tigerId] = newOwner;
        balanceOf[newOwner]++;
        if (!firstSale) {
            balanceOf[previousOwner]--;

            // To prevent a gap in previousOwner's tokens array
            // we store the last token in the index of the token to delete, and
            // then delete the last slot (swap and pop).

            uint256 lastTokenIndex = balanceOf[previousOwner];
            uint256 tokenIndex = tigersOwnedByIndex[tigerId];

            // When the token to delete is the last token, the swap operation is unnecessary
            if (tokenIndex != lastTokenIndex) {
                uint256 lastTokenId = tigersOwnedBy[previousOwner][lastTokenIndex];
                // Move the last token to the slot of the to-delete token
                tigersOwnedBy[previousOwner][tokenIndex] = lastTokenId;
                // Update the moved token's index
                tigersOwnedByIndex[lastTokenId] = tokenIndex;
            }

            delete tigersOwnedBy[previousOwner][lastTokenIndex];
        }
        uint256 newIndex = balanceOf[newOwner] - 1;
        tigersOwnedBy[newOwner][newIndex] = tigerId;
        tigersOwnedByIndex[tigerId] = newIndex;
    }

    // allow someone to buy a tiger offered for sale
    function buyTiger(uint256 tigerId) external payable {
        address caller = msg.sender;
        uint256 value = msg.value;
        charges = _serviceFee(value);
        royalty = _royaltyFee(value);
        uint256 netAmount;

        require(tigerId < totalSupply, "index out of range");
        SaleOffer memory saleOffer = getSaleInfo(tigerId);
        require(saleOffer.isForSale, "not for sale");
        require(value >= saleOffer.price, "price not met");
        require(saleOffer.seller == getOwner(tigerId), "seller no longer owns");

        // if condition to check if artist or resaler

        if (saleOffer.seller == artist) {
            // if artist just remove service fee and sends to the deployer

            updateTigerOwnership(tigerId, caller, saleOffer.seller);
            tigersForSale[tigerId] = SaleOffer(false, ZEROADDRESS, 0);
            netAmount = value - charges;
            pendingWithdrawals[deployer] += charges;
            pendingWithdrawals[saleOffer.seller] += netAmount;
            emit TigerSold(saleOffer.seller, caller, tigerId, saleOffer.price);
        }else {
            // if resale remove both the service fee and royalty fee, send the royalty to artist
            // and the service fee to the deployer

            updateTigerOwnership(tigerId, caller, saleOffer.seller);
            tigersForSale[tigerId] = SaleOffer(false, ZEROADDRESS, 0);
            netAmount = value - charges - royalty;
            pendingWithdrawals[artist] += royalty;
            pendingWithdrawals[deployer] += charges;
            pendingWithdrawals[saleOffer.seller] += netAmount;
            emit TigerSold(saleOffer.seller, caller, tigerId, saleOffer.price);
        }
    }

    // allow the artist to take pending withrawals of the proceeds from the sale of the token
    function withdrawFunds(uint256 amount) external {
        address caller = msg.sender;
        require(caller != ZEROADDRESS, "Cannot send to address zero");
        require(amount > 0, "Amount should be greater than 0");
        require(pendingWithdrawals[caller] >= amount, "Insufficient balance");
        pendingWithdrawals[caller] -= amount;
        (bool success,) = caller.call{value: amount}("");
        require(success, "Transfer failed");
        emit FundsWithdrawn(caller, amount);
    }

    // royalty fee
    function _royaltyFee(uint256 amount) internal view returns (uint256 artistFee) {
        artistFee = (amount * artistFeePercentage) / 100;
    }

    // service fee
    function _serviceFee(uint256 amount) internal view returns (uint256 serviceFee) {
        serviceFee = (amount * serviceFeePercentage) / 100;
    }
}
