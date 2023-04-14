// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Marketplace is ERC721Holder{

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // state variables------------------------------------------------------------------------
    uint256 public serviceFee;
    address public nftContract;
    address payable public marketPlaceOwner;
    Counters.Counter private listingId;

    // constuctor-----------------------------------------------------------------------------
    constructor(uint256 _serviceFee , address _nftContract){
        serviceFee = _serviceFee;
        nftContract = _nftContract;
        marketPlaceOwner = payable(msg.sender);
    }

    // structs--------------------------------------------------------------------------------
    struct FixpriceListing{
        bool isListed;
        uint256 price;
        address seller;
        uint256 tokenid;
    }

    struct AuctionListing{
        bool isSold;
        bool isListed;
        address seller;
        uint256 tokenid;
        uint256 endTime;
        uint256 reservePrice;
    }

    struct bidding{
        uint256 currentBidValue;
        address currentBidder;
    }

    // mappings-------------------------------------------------------------------------------
    mapping(uint256=> bidding) public bidinformation;
    mapping(uint256 => AuctionListing) public auctionListings;
    mapping(uint256 => FixpriceListing) public fixpriceListings;

    // modifires------------------------------------------------------------------------------
    modifier adminOnly(){
        require(msg.sender == marketPlaceOwner,"unautherized caller");
        _;
    }
    // events---------------------------------------------------------------------------------
    event fixpriceListed(uint256 indexed tokenid , uint256 price , address indexed seller);
    event auctionListed(uint256 indexed tokenid , uint256 reservePrice , address indexed seller , uint256 _listedOn);
    event currentBid(uint256 indexed bidValue , address indexed bidder , uint256 indexed previousBid , address previousBidder);
    event buyFixpriceNft(uint256 indexed tokenid , uint256 indexed totalPricePaid , address indexed buyer , uint256 priceForSeller , uint256 servicefee);
    
    
    // functions------------------------------------------------------------------------------

    // admin functions------------------------------------------------------------------------

    // calculation functions------------------------------------------------------------------

    function calculateServiceFee(uint256 _nftprice , uint256 _pbp) private pure returns(uint256){
        uint256 servicefees = _nftprice.mul(_pbp).div(10000);
        return servicefees;
    }
    function updateServiceFee(uint256 _newServiceFee) public adminOnly{
        require(_newServiceFee <= 1000 && _newServiceFee >=100 , "Can not be greater than 10 % ");
        serviceFee = _newServiceFee;
    }

    // user functions-------------------------------------------------------------------------

    function listNftOnFixedprice(uint256 _tokenid , uint256 _price) public {
        require(_price > 0 , "price can not be zero");
        require(!fixpriceListings[_tokenid].isListed , "already listed");
        fixpriceListings[_tokenid] = FixpriceListing({
            isListed:true,
            price:_price,
            seller:msg.sender,
            tokenid:_tokenid
        });
        IERC721(nftContract).safeTransferFrom(msg.sender , address(this) , _tokenid);
        emit fixpriceListed(_tokenid, _price, msg.sender);
    }

    function listNftOnAuction(uint256 _tokenid , uint256 _reservePrice , uint256 _endTime) public{
        require(_reservePrice > 0 , "price can not be zero");
        require(!auctionListings[_tokenid].isListed , "already listed");
        require(_endTime >= block.timestamp.add(5 minutes) , "auction period at least for 10 minutes");

        auctionListings[_tokenid] = AuctionListing({
            isSold:false,
            isListed:true,
            seller:msg.sender,
            tokenid:_tokenid,
            endTime:_endTime,
            reservePrice:_reservePrice
        });

        IERC721(nftContract).safeTransferFrom(msg.sender , address(this) , _tokenid);
        emit auctionListed(_tokenid, _reservePrice, msg.sender , block.timestamp);
    }

    function buyFixedpriceNft(uint256 _tokenid) public payable {
        require(msg.sender != fixpriceListings[_tokenid].seller , "can not buy your own item");
        require(msg.value == fixpriceListings[_tokenid].price , "pay exact price");

        uint256 servicefee = calculateServiceFee(msg.value, serviceFee);
        marketPlaceOwner.transfer(servicefee);
        uint256 priceToSeller = msg.value.sub(servicefee);
        payable(fixpriceListings[_tokenid].seller).transfer(priceToSeller);

        IERC721(nftContract).safeTransferFrom(address(this) , msg.sender , _tokenid);
        emit buyFixpriceNft(_tokenid , msg.value , msg.sender , priceToSeller ,servicefee);
        delete fixpriceListings[_tokenid];
    }



    function bidOnAuction(uint256 _tokenid) public payable{
        require(msg.sender != auctionListings[_tokenid].seller ,"seller can not bid");
        require(msg.value >= auctionListings[_tokenid].reservePrice , "bid can not be less then reserve price");
        require(msg.value > bidinformation[_tokenid].currentBidValue , "place high bid then existing");
        
        uint256 currentBidVal = bidinformation[_tokenid].currentBidValue;
        address currentBidder = bidinformation[_tokenid].currentBidder;

        payable(currentBidder).transfer(currentBidVal);

        bidinformation[_tokenid].currentBidder = msg.sender;
        bidinformation[_tokenid].currentBidValue = msg.value;

        emit currentBid(msg.value , msg.sender , currentBidVal , currentBidder);
    }

    function endAuction(uint256 _tokenid)  public {
        
    }

    function claimNft(uint256 _tokenid)  public {
        
    }

    function removeListingFixedprice(uint256 _tokenid) public{

    }

    function removeListingAuction(uint256 _tokenid) public {

    }
}