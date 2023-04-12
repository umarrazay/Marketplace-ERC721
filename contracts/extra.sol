// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// interface INFT
// {
//     function ownerOf(uint256 tokenId) external view returns (address owner);
//     function balanceOf(address owner) external view returns (uint256 balance);
//     function getMinter(uint256 _tokenid) external view returns(address _minterAddress) ;
//     function getRoyaltyPercentage(uint256 _tokenid , address _address) external view returns(uint256 _royaltyPercentage);
// }


// contract Marketplace is ERC721Holder 
// {

//     using SafeMath for uint256;
//     using Counters for Counters.Counter;

//     INFT private inft;
//     uint256 private platformFee = 250;
//     Counters.Counter private _listingId;

//     address public NFTcontract;
//     address public MarketPlaceOwner = msg.sender;

//     constructor(address _NFTcontract)
//     {
//         NFTcontract  = _NFTcontract;  
//     }

//     struct FixedPriceItem
//     {
//         bool isSold;
//         bool isListed;
//         uint256 tokenId;
//         uint256 nftPrice;
//         uint256 royaltyfee;
//         address seller;
//         address nftAddress;
//         address royaltyReciever;
//     }mapping(uint256 => FixedPriceItem) public mFixedPriceItem;


//     event 
//     efixedPriceListing
//     (
//         uint256 _tokenId, 
//         uint256 _nftPrice, 
//         address _seller
//     );

//     event 
//     eBuyFixedPriceItem
//     (   
//         address _buyer,
//         address _seller,
//         uint256 _tokenId, 
//         uint256 _nftPrice
//     );
//     event
//     eDFeeTransfers
//     (
//         uint256 _totalPrice,
//         uint256 _platformfee,
//         uint256 _royaltyfee,
//         uint256 _tokenid
//     );
//     event 
//     eFromFixedPriceListing
//     (
//         uint256 _tokenid , 
//         uint256 _removedAt , 
//         address _remover
//     );


//     function listItemForFixedPrice(uint256 _tokenid , uint256 _nftPrice) public returns(bool isListed)
//     {
//         inft = INFT(NFTcontract);
         
//         require(_tokenid  >=0, "Marketplace:: invalid token id");
//         require(!mFixedPriceItem[_tokenid].isListed , "Marketplace:: already listed");
//         require(_nftPrice > 0 ,"Marketplace:: price can not be zero");
//         require(msg.sender == inft.ownerOf(_tokenid), "Marketplace:: do not have any nft or not owner");

//         mFixedPriceItem[_tokenid] = FixedPriceItem({
//             isSold:false,
//             isListed:true,
//             tokenId: _tokenid,
//             nftPrice:_nftPrice,
//             royaltyfee:inft.getRoyaltyPercentage(_tokenid, NFTcontract),
//             seller:msg.sender,
//             nftAddress:NFTcontract,
//             royaltyReciever: inft.getMinter(_tokenid)
//         });

//         IERC721(NFTcontract).transferFrom(msg.sender,address(this),_tokenid);    

//         emit
//         efixedPriceListing
//         (
//             _tokenid,
//             _nftPrice,
//             msg.sender
//         );
//         return true;
//     }

//     function calcPlatFormFee(uint256 _nftprice , uint256 _pbp) private pure returns(uint256){
//         uint256 platformfee = _nftprice.mul(_pbp).div(10000);
//         return platformfee;
//     }
//     function calcRoyaltyFee(uint256 _nftprice , uint256 _pbp) private pure returns(uint256){
//         uint256 royaltyfee = _nftprice.mul(_pbp).div(10000);
//         return royaltyfee;
//     }
  
//     function buyFixedPriceItem(uint256 _tokenid) public payable returns(bool isBought)
//     {
//         require(_tokenid >= 0 , "Marketplace:: invalid listing id");   
//         require(mFixedPriceItem[_tokenid].isListed,"Marketplace:: NFT is not listed for sale");
//         require(msg.sender != mFixedPriceItem[_tokenid].seller, "Marketplace:: you can not buy your own nft");     
//         require(msg.value == mFixedPriceItem[_tokenid].nftPrice,"Marketplace:: pay exact price");

//         uint256 platformfee = calcPlatFormFee(msg.value,platformFee);
//         uint256 royaltyfee  = calcRoyaltyFee(msg.value,mFixedPriceItem[_tokenid].royaltyfee);

//         uint256 totalFee = platformfee.add(royaltyfee);
//         uint256 paymentToSeller = msg.value.sub(totalFee);

//         payable(MarketPlaceOwner).transfer(platformfee);
//         payable(mFixedPriceItem[_tokenid].royaltyReciever);
//         payable(mFixedPriceItem[_tokenid].seller).transfer(paymentToSeller);

//         IERC721(NFTcontract).transferFrom(address(this),msg.sender,_tokenid);   
        
//         mFixedPriceItem[_tokenid].isSold = true;
//         mFixedPriceItem[_tokenid].isListed = false;

//         emit
//         eDFeeTransfers
//         (
//             msg.value, 
//             platformfee, 
//             royaltyfee,
//            _tokenid
//         );

//         emit
//         eBuyFixedPriceItem
//         (
//             msg.sender,
//             mFixedPriceItem[_tokenid].seller,
//            _tokenid,
//             msg.value
//         );
//         return true;
//     }

//     function removeFromListingFixPrice(uint256 _tokenid) public 
//     {
//         require(_tokenid >=  0 , "Marketplace:: invalid tokend id");
//         require(msg.sender == mFixedPriceItem[_tokenid].seller , "Marketplace:: you are not the owner");
//         require(mFixedPriceItem[_tokenid].isListed , "Marketplace:: NFT is already unlisted");
       
//         if(mFixedPriceItem[_tokenid].isSold == false){


//             mFixedPriceItem[_tokenid] = FixedPriceItem({
//                 isSold:false,
//                 isListed:false,
//                 tokenId: _tokenid,
//                 nftPrice:mFixedPriceItem[_tokenid].nftPrice,
//                 royaltyfee:mFixedPriceItem[_tokenid].royaltyfee,
//                 seller:msg.sender,
//                 nftAddress:NFTcontract,
//                 royaltyReciever:mFixedPriceItem[_tokenid].royaltyReciever
//             });

//             IERC721(NFTcontract).transferFrom(address(this),msg.sender,_tokenid);   

//         }
//         else if(mFixedPriceItem[_tokenid].isSold == true)
//         {
//             revert ("Marketplace:: NFT is alredy sold");
//         }

//         emit eFromFixedPriceListing
//         (
//             _tokenid,
//             block.timestamp,
//             msg.sender
//         );
//     }

//     struct Auction
//     {
//         bool isSold;
//         bool isListed;
//         bool openForBid;
//         uint256 tokenId;
//         uint256 minNFTprice;
//         uint256 auctionStartTime;
//         uint256 auctionEndTime;
//         uint256 currentBid;
//         uint256 royaltyfee;
//         address cBidder;
//         address seller;
//         address nftAddress;
//         address royaltyReciever;
//     }mapping(uint256 => Auction) public mAuctions;



//     function listItemForAuction(uint256 _tokenid , uint256 _minNFTprice , uint256 _auctionEndTime , uint256 _auctionStartTime) public returns(bool isListed)
//     {

//         inft = INFT(NFTcontract);
         
//         require(_tokenid  >=0, "Marketplace:: invalid token id");
//         require(!mAuctions[_tokenid].isListed , "Marketplace:: already listed");
//         require(_minNFTprice > 0 ,"Marketplace:: price can not be zero");
//         require(msg.sender == inft.ownerOf(_tokenid), "Marketplace:: do not have any nft or not owner");
//         require(_auctionStartTime > block.timestamp , "Marketplace:: auction start time can not be the past time");
//         require(_auctionEndTime > block.timestamp , "Marketplace:: auction end time should be in future");

//         mAuctions[_tokenid] = Auction({
//             isSold:false,
//             isListed:true,
//             openForBid:true,
//             tokenId: _tokenid,
//             minNFTprice:_minNFTprice,
//             auctionStartTime:_auctionStartTime,
//             auctionEndTime:_auctionEndTime,
//             currentBid:0,
//             royaltyfee:inft.getRoyaltyPercentage(_tokenid, NFTcontract),
//             cBidder:address(0),
//             seller:msg.sender,
//             nftAddress:NFTcontract,
//             royaltyReciever: inft.getMinter(_tokenid)
//         });

//         IERC721(NFTcontract).transferFrom(msg.sender,address(this),_tokenid);            
//         return true;
//     }

//     function placeBid(uint256 _tokenid) public payable returns(bool isBidPlaced)
//     {
//         require(block.timestamp < mAuctions[_tokenid].auctionStartTime, "Auction is not started yet");
//         require(block.timestamp >= mAuctions[_tokenid].auctionEndTime , "Auction is alread ended");

//         require(msg.sender != mAuctions[_tokenid].seller , "Marketplace:: Seller can not bid");
//         require(msg.sender != address(0) , "Marketplace:: invalid user address");
//         require(_tokenid>=0,"Marketplace:: invalide token id");
//         require(msg.value >= mAuctions[_tokenid].minNFTprice , "Marketplace:: Bid should be greater or equal to the minimum price");

//         uint256 currentBid = mAuctions[_tokenid].currentBid;
//         address currentBidOwner = mAuctions[_tokenid].cBidder;

//         if(msg.value <= currentBid)
//         {
//             revert("There is already a higher or equal bid placed");
//         }
//         if(msg.value > currentBid)
//         {
//             payable(currentBidOwner).transfer(currentBid);
//         }

//         mAuctions[_tokenid].cBidder = msg.sender;
//         mAuctions[_tokenid].currentBid = msg.value;

//         return true;
//     }



// }