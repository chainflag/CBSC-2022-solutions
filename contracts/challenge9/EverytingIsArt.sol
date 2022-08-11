pragma solidity ^0.6.0;

// Using  @openzeppelin/contracts@3.2.0
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract EverytingIsArt is ERC721 {
    using SafeMath for *;

    uint256 public totalMinted;

    bool public hope = true;
    bool public hope2 = true;

    // Deploy by CTFer EOA account
    constructor() public ERC721("All Arts", "AA") {}

    function becomeAnArtist(uint256 _count) public returns (bool) {
        require(_count >= 288, "Why don't you want to be an artist?");

        for (uint256 i = 0; i < _count; i++) {
            uint256 tokenId = totalMinted.add(1);
            _safeMint(msg.sender, tokenId);
            totalMinted = totalMinted.add(1);
        }

        return true;
    }

    function theHope() public returns (bool) {
        require(hope, "Hope broken");
        require(uint64(msg.sender).mod(88) != 0, "Try again!");

        uint256 tokenId = totalMinted.add(1);
        totalMinted = totalMinted.add(1);
        _safeMint(msg.sender, tokenId);

        hope = false;
        return true;
    }

    function hopeIsInSight() public returns (bool) {
        require(hope == false, "Try again!");
        require(hope2 == true, "Hope broken!");
        require(uint64(msg.sender).mod(88) == 0, "Try again!");

        uint256 tokenId = totalMinted.add(1);
        totalMinted = totalMinted.add(1);
        _safeMint(msg.sender, tokenId);

        hope2 = false;
        return true;
    }

    // Artist or programmer? Just try again and again.
    function isCompleted() public view returns (bool) {
        require(
            balanceOf(msg.sender) == 288,
            "You are not yet a good artist, you should keep trying."
        );

        return true;
    }
}