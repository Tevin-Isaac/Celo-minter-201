//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./NFT.sol";


contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemId;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 public mintingCost = 0.0001 ether;

    constructor(){
        owner = payable(msg.sender);
    }

    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }

    struct _Item {
        ListingStatus status;
        address nftContract;
        address payable owner;
        address payable creator;
        uint256 token;
        uint256 price;
    }

    event Item (
        address nftContract,
        address owner,
        address creator,
        uint256 token,
        uint256 price
    );

    event CancelSell(
        uint256 token,
        address owner
    );

    event Sold(
        address nftContract,
        address owner,
        address creator,
        uint256 token,
        uint256 price
    );

    mapping(uint => _Item) public Items;

    mapping(address => uint) createdPerWallet;
    mapping(address => uint) ownedPerWallet;

    bool isPaused;

    function sellItem(string memory uri,uint256 _price,address _nftContract) public payable notPaused nonReentrant{
        require(_price > 0, "Price must be at least 1 wei");
        require(msg.value == mintingCost, "You need to pay minting price");
        require(_nftContract != address(0), "Enter a valid marketplace address");
        require(bytes(uri).length > 0, "Enter a valid uri");

        uint256 itemId = _itemId.current();
        _itemId.increment();
        createdPerWallet[msg.sender]++;
        uint256 _tokenId = NFT(_nftContract).safeMint(uri,address(this),msg.sender);

        Items[itemId] =  _Item(
            ListingStatus.Active,
            _nftContract,
            payable(address(this)),
            payable(msg.sender),
            _tokenId,
            _price
        );

        IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

        emit Item(
            _nftContract,
            payable(address(this)),
            payable(msg.sender),
            _tokenId,
            _price
        );

    }

    function cancelSell(uint256 _tokenId) public isValidTokenId(_tokenId) notPaused {
        _Item storage listedItem = Items[_tokenId];
        require(msg.sender == listedItem.owner || msg.sender == listedItem.creator, "Only owner can cancel listing");
        require(listedItem.status == ListingStatus.Active, "Listing is not active");

        listedItem.status = ListingStatus.Cancelled;
        IERC721(listedItem.nftContract).transferFrom(address(this), msg.sender, listedItem.token);

        emit CancelSell(listedItem.token,listedItem.owner);
    }

    function buyItem(uint256 _tokenId) public payable isValidTokenId(_tokenId) notPaused nonReentrant {
        _Item storage listedItem = Items[_tokenId];

        require(listedItem.price == msg.value, 'Price must be equal to NFT price');

        //Update the owner & status
        listedItem.owner = payable(msg.sender);
        listedItem.status = ListingStatus.Sold;

        ownedPerWallet[msg.sender]++;
        address payable ownerAddress = listedItem.creator;
        if(listedItem.owner == address(0)){
            ownerAddress = listedItem.owner;
        }
        (bool success,) = ownerAddress.call{value: msg.value}("");
        require(success, "Transfer of payment failed");
        //Tranfer NFT to the new owner
        _itemsSold.increment();
        IERC721(listedItem.nftContract).transferFrom(address(this), msg.sender, listedItem.token);

        //Pay owner of the NFT
        (bool sent, ) = payable(owner).call{value: mintingCost}("");
        require(sent, "Transfer of mintCost failed");

        emit Sold(
            listedItem.nftContract,
            msg.sender,
            listedItem.creator,
            listedItem.token,
            listedItem.price
        );

    }

    // Fetch all unsold items
    function fetchMarketItems() public view returns (_Item[] memory) {
        uint itemCount = _itemId.current();
        uint unsoldItemCount = _itemId.current() - _itemsSold.current();
        uint currentIndex = 0;

        _Item[] memory items = new _Item[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (Items[i].owner == address(this) && Items[i].status == ListingStatus.Active) {
                _Item storage currentItem = Items[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Fetch creator NFT's
    function fetchCreatorItemsListed() public view hasCreatedItems returns (_Item[] memory) {
        uint totalItemCount = _itemId.current();
        uint itemCount = createdPerWallet[msg.sender];
        _Item[] memory items = new _Item[](itemCount);
        uint currentIndex = 0;

        for(uint i = 0; i < totalItemCount; i++) {
            if(Items[i].creator == msg.sender){
                _Item storage currentItem = Items[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }


    // Fetch owner NFT's
    function fetchOwnerItemsListed() public view hasOwnerItems  returns (_Item[] memory) {

        uint totalItemCount = _itemId.current();
        uint itemCount = ownedPerWallet[msg.sender];
        uint currentIndex = 0;
        _Item[] memory items = new _Item[](itemCount);

        for (uint i = 0; i < totalItemCount; i++) {
            if(Items[i].owner == msg.sender){
                _Item storage currentItem = Items[i];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function pause() public onlyOwner {
        isPaused = true;
    }

    function unPause() public onlyOwner {
        isPaused = false;
    }


    modifier hasCreatedItems {
        require(createdPerWallet[msg.sender] > 0, "You have not yet created any items");
        _;
    }

    modifier hasOwnerItems {
        require(ownedPerWallet[msg.sender] > 0, "You currently own no items");
        _;
    }

    modifier isValidTokenId(uint _tokenId) {
        require(_tokenId >= 0, "Enter a valid tokenId");
        _;
    }

    //     pause all minting and selling actions
    modifier notPaused() {
        require(!isPaused, "Contract is paused");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }


}
