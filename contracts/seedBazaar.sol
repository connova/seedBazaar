// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract SeedBazaar is ERC721 {
    address bazaarOwner;
    string private _name;
    string private _symbol;
    string private _baseURI;

    //constructor
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        bazaarOwner = msg.sender;
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    modifier _ownerOnly() {
        require(
            msg.sender == bazaarOwner,
            "Only the bazaar owner can conduct this action"
        );
        _;
    }

    //events
    event Transfer(address from, address to, uint256 seedId);
    event Approval(address from, address to, uint256 seedId);
    event ApprovalForAll(address from, address to, bool);

    //struct for seeds
    struct Seed {
        string name;
        string description;
        uint256 quantity;
    }
    Seed[] public seeds;
    EnumerableMap.UintToAddressMap private _seedOwners;
    mapping(address => EnumerableSet.UintSet) private _holderSeeds;
    mapping(uint256 => address) private _vendorApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _seedURIs;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    //mint function to register seed to a specific address

    function _safeMint(address to, uint256 tokenId) internal virtual override {
        _safeMint(to, tokenId, "Succesful");
    }

    function _safeMint(
        address to,
        uint256 seedId,
        bytes memory _data
    ) internal virtual override {
        _mint(to, seedId);
        require(
            _checkOnERC721Received(address(0), to, seedId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 seedId) internal virtual override {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(seedId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, seedId);

        _holderSeeds[to].add(seedId);

        _seedOwners.set(seedId, to);

        emit Transfer(address(0), to, seedId);
    }

    //sell seed
    function _transfer(
        address from,
        address to,
        uint256 seedId
    ) internal virtual override {
        require(
            ownerOf(seedId) == from,
            "ERC721: transfer of seed that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, seedId);

        // Clear approvals from the previous owner
        _approve(address(0), seedId);

        _holderSeeds[from].remove(seedId);
        _holderSeeds[to].add(seedId);

        _seedOwners.set(seedId, to);

        emit Transfer(from, to, seedId);
    }

    function _setTokenURI(uint256 seedId, string memory _seedURI)
        internal
        virtual
        override
    {
        require(
            _exists(seedId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _seedURIs[seedId] = _seedURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual override {
        _baseURI = baseURI_;
    }

    function tokenURI(uint256 seedId)
        public
        override
        view
        returns (string memory)
    {
        require(
            _exists(seedId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _seedURI = _seedURIs[seedId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _seedURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_seedURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _seedURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, seedId.toString()));
    }

    function baseURI() public override view returns (string memory) {
        return _baseURI;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        override
        view
        returns (uint256)
    {
        return _holderSeeds[owner].at(index);
    }

    function totalSupply() public override view returns (uint256) {
        return _seedOwners.length();
    }

    function tokenByIndex(uint256 index)
        public
        override
        view
        returns (uint256)
    {
        (uint256 seedId, ) = _seedOwners.at(index);
        return seedId;
    }

    function _exists(uint256 seedId) internal override view returns (bool) {
        return _seedOwners.contains(seedId);
    }

    function _approve(address to, uint256 seedId) public override _ownerOnly {
        _vendorApprovals[seedId] = to;
        emit Approval(ownerOf(seedId), to, seedId);
    }

    //get address approved for a token
    function getApproved(uint256 seedId)
        public
        virtual
        override
        view
        returns (address)
    {
        require(
            _exists(seedId),
            "ERC721: approved query for nonexistent token"
        );

        return _vendorApprovals[seedId];
    }

    //allow a vendor to sell a specific seed
    function approve(address to, uint256 seedId) public virtual override {
        address owner = ownerOf(seedId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, seedId);
    }

    //set an approval for an address giving sales rights for all seeds
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    //check if an address has the sales rights for all seeds
    function isApprovedForAll(address owner, address operator)
        public
        virtual
        override
        view
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 seedId)
        internal
        override
        view
        returns (bool)
    {
        require(
            _exists(seedId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(seedId);
        return (spender == owner ||
            getApproved(seedId) == spender ||
            isApprovedForAll(owner, spender));
    }

    //transfer seed from one account to another if you have approval or are the owner
    function transferFrom(
        address from,
        address to,
        uint256 seedId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), seedId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, seedId);
    }

    //safely transfer from one account to another if you are approved or the owner
    function safeTransferFrom(
        address from,
        address to,
        uint256 seedId
    ) public virtual override {
        safeTransferFrom(from, to, seedId, "");
    }

    //same as above but with extra data pramater
    function safeTransferFrom(
        address from,
        address to,
        uint256 seedId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), seedId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, seedId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 seedId,
        bytes memory _data
    ) internal virtual override {
        _transfer(from, to, seedId);
        require(
            _checkOnERC721Received(from, to, seedId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 seedId,
        bytes memory _data
    ) private override returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = to.call(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                _msgSender(),
                from,
                seedId,
                _data
            )
        );
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }

    //check how many seeds are at an account
    function balanceOf(address owner)
        public
        virtual
        override
        view
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );

        return _holderSeeds[owner].length();
    }

    //check who owns a certain seed
    function ownerOf(uint256 tokenId)
        public
        virtual
        override
        view
        returns (address)
    {
        return
            _seedOwners.get(
                tokenId,
                "ERC721: owner query for nonexistent token"
            );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 seedId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, seedId);
    }

    function _burn(uint256 seedId) internal virtual override {
        address owner = ownerOf(seedId);

        _beforeTokenTransfer(owner, address(0), seedId);

        // Clear approvals
        _approve(address(0), seedId);

        // Clear metadata (if any)
        if (bytes(_seedURIs[seedId]).length != 0) {
            delete _seedURIs[seedId];
        }

        _holderSeeds[owner].remove(seedId);

        _seedOwners.remove(seedId);

        emit Transfer(owner, address(0), seedId);
    }
}
