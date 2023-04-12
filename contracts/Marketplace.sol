// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// interface
interface INFT{
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Marketplace is ERC721Holder {

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // state variables------------------------------------------------------------------------

    INFT private iNfts;
    uint256 private serviceFee;
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

    // mappings-------------------------------------------------------------------------------

    mapping(uint256 => AuctionListing) public auctionListings;
    mapping(uint256 => FixpriceListing) public fixpriceListings;

    // modifires------------------------------------------------------------------------------

    modifier adminOnly(){
        require(msg.sender == marketPlaceOwner,"unautherized caller");
        _;
    }

    modifier validateOwner(uint256 _tokenid) {
        require(msg.sender == iNfts.ownerOf(_tokenid) , "you are not the owner");
        _;
    }

    // events---------------------------------------------------------------------------------

    event fixpriceListed(uint256 indexed tokenid , uint256 price , address indexed seller);
    event auctionListed(uint256 indexed tokenid , uint256 reservePrice , address indexed seller , uint256 _listedOn);
    event buyFixpriceNft(uint256 indexed tokenid , uint256 indexed pricePaid , address indexed buyer , uint256 servicefee);
    
    // functions------------------------------------------------------------------------------

    // admin functions------------------------------------------------------------------------

    // calculation functions------------------------------------------------------------------

    function calculateServiceFee(uint256 _nftprice , uint256 _pbp) private pure returns(uint256){
        uint256 servicefees = _nftprice.mul(_pbp).div(10000);
        return servicefees;
    }

    // user functions-------------------------------------------------------------------------

    function listNftOnFixedprice(uint256 _tokenid , uint256 _price) public validateOwner(_tokenid){
        require(_price > 0 , "price can not be zero");
        require(!fixpriceListings[_tokenid].isListed , "already listed");

        fixpriceListings[_tokenid] = FixpriceListing({
            isListed:true,
            price:_price,
            seller:msg.sender,
            tokenid:_tokenid
        });

        iNfts.safeTransferFrom(msg.sender , address(this) , _tokenid);
        emit fixpriceListed(_tokenid, _price, msg.sender);
    }

    function listNftOnAuction(uint256 _tokenid , uint256 _reservePrice , uint256 _endTime) public  validateOwner(_tokenid){
        require(_reservePrice > 0 , "price can not be zero");
        require(!auctionListings[_tokenid].isListed , "already listed");
        require(_endTime >= 5 minutes , "auction period at least for 10 minutes");

        auctionListings[_tokenid] = AuctionListing({
            isSold:false,
            isListed:true,
            seller:msg.sender,
            tokenid:_tokenid,
            endTime:_endTime,
            reservePrice:_reservePrice
        });

        iNfts.safeTransferFrom(msg.sender , address(this) , _tokenid);
        emit auctionListed(_tokenid, _reservePrice, msg.sender , block.timestamp);
    }

    function buyFixedpriceNft(uint256 _tokenid) public payable {
        require(msg.sender != fixpriceListings[_tokenid].seller , "can not buy your own item");
        require(msg.value == fixpriceListings[_tokenid].price , "pay exact price");

        uint256 feePayToMPO = calculateServiceFee(msg.value, serviceFee);
        marketPlaceOwner.transfer(feePayToMPO);
        payable(fixpriceListings[_tokenid].seller).transfer(msg.value.sub(feePayToMPO));

        emit buyFixpriceNft(_tokenid , msg.value , msg.sender , feePayToMPO);
        delete fixpriceListings[_tokenid];
    }

    function bidOnAuction(uint256 _tokenid) public{
        
    }

    function endAuction(uint256 _tokenid)  public {
        
    }

    function claimNft(uint256 _tokenid)  public {
        
    }

    function removeListingFixedprice(uint256 _tokenid) public  validateOwner(_tokenid){

    }

    function removeListingAuction(uint256 _tokenid) public  validateOwner(_tokenid){

    }
}