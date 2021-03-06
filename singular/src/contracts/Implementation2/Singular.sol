pragma solidity ^0.4.24;

import "../ISingularWallet.sol";
import "../ISingular.sol";
import "./Commenting.sol";
import "./TransferHistory.sol";
import "./SingularMeta.sol";
/**
 * @title Concrete asset token representing a single piece of asset, with
 * support of ownership transfers and transfer history.
 *
 * The owner of this item must be an instance of `SingularOwner`
 *
 * See the comments in the Singular interface for method documentation.
 * 
 * 
 * @author Bing Ran<bran@udap.io>
 *
 */
contract Singular is ISingular, SingularMeta, TransferHistory, Commenting {

    ISingularWallet public owner; /// current owner
    ISingularWallet public nextOwner; /// next owner choice
    ISingularWallet public ownerPrevious; /// next owner choice


    address internal theCreator; /// who creates this token

    uint256 expiry;
    string senderNote;
    string receiverNote;



    constructor(string _name, string _symbol, string _descr, string _tokenURI)
    SingularMeta(_name, _symbol, _descr, _tokenURI)
    public
    {
        theCreator = msg.sender;
    }

    function creator()
    view
    external
    returns (
        address         ///< the owner elected
    ) {
        return theCreator;
    }
    /**
     * get the current owner as type of SingularOwner
     */
    function previousOwner() view external returns (ISingularWallet) {
        return ownerPrevious;
    }

    /**
     * get the current owner as type of SingularOwner
     */
    function currentOwner() view external returns (ISingularWallet) {
        return owner;
    }

    /**
     * There can only be one approved receiver at a given time. This receiver cannot
     * be changed before the expiry time.
     * Can only be called by the token owner (in the form of SingularOwner account or
     * the naked account address associated with the currentowner) or an approved operator.
     * Note: the approved receiver can only accept() or reject() the offer. His power is limited
     * before he becomes the owner. This is in contract to the the transferFrom() of ERC20 or
     * ERC721.
     *
     */
    function approveReceiver(
        ISingularWallet _to, 
        uint256 _expiry, 
        string _reason
        ) 
        external
        NotInTransition 
    {
        
        require(address(_to) != address(0) && owner.isActionAuthorized(msg.sender, "approveReceiver", this));
        expiry = _expiry;
        senderNote = _reason;
        nextOwner = _to;
        emit  ReceiverApproved(address(owner), address(nextOwner), expiry, senderNote);
    }

    /**
     * The approved account takes the ownership of this token. The caller must have
     * been set as the next owner of this token previously in a call by the current
     * owner to the approve() function. The expiry time must be in the future
     * as of now. This function MUST call the sent() method on the original owner.
     TODO: evaluate re-entrance attack
     */
    function accept(string _reason) external InTransition {
        require(
            address(nextOwner) != address(0) && 
            nextOwner.isActionAuthorized(msg.sender, "accept", this)
        );
        ownerPrevious = owner;
        owner = nextOwner; // the single most important step!!!
        reset();
        transferHistory.push(TransferRec(ownerPrevious, owner, now, senderNote, _reason, this));
        uint256 moment = now;
        ownerPrevious.sent(this, _reason);
        owner.received(this, _reason);
        emit Transferred(address(ownerPrevious), address(owner), moment, senderNote, _reason);

    }

    /**
     * reject an offer. Must be called by the approved next owner(from the address
     * of the SingularOwner or SingularOwner.ownerAddress()).
     */
    function reject() external {
        address sender = msg.sender;
        require(
            sender == address(nextOwner) ||
            nextOwner.isActionAuthorized(sender, "reject", this)
            );
        reset();
    }

    function reset() internal {
        delete expiry;
        delete senderNote;
        delete nextOwner;
    }

    /**
     * to send this token synchronously to a SingularWallet. It must call approveReceiver
     * first and invoke the "offer" function on the other SingularWallet. Setting the
     * current owner directly is not allowed.
     */
    function sendTo(
        ISingularWallet _to, 
        string _reason
        ) 
        external 
        {
        this.approveReceiver(_to, now + 60, _reason);
        _to.offer(this, _reason);
        }
    


    /// implement Commenting interface
    function makeComment(string _comment) public {
        require(owner.isActionAuthorized(msg.sender, "makeComment", this));
        addComment(msg.sender, now, _comment); 
    }


    modifier NotInTransition() {
        require(now > expiry);
        _;
    }

    modifier InTransition() {
        require(now <= expiry);
        _;
    }

}
