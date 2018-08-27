pragma solidity ^0.4.24;

import "./AssetOwner.sol";

/*
 * @title Concreate asset token representing a single piece of asset, with 
 * suppor of ownership transfers and transfer history.
 * 
 * The owner of this item must be , defined in the AssetOwnerImpl.sol.
 * 
 * Transfer in one step:
 * 
 * The sendTo() method basically approves the transition first and notify the other
 * party via an AssetOwner.offer() call, which in turn evaluate the
 * ownership offer before accept it or reject it. 
 *  
 * Transfer in two steps:
 * 
 * The approveReceiver method is a timelock on the ownership. The 
 * receiver can take the ownership within the valid peroid of time. Before the expiry 
 * time, this token is locked for the receiver exlusively and cannot be locked
 * again for any other receivers. The contract serves as a 
 * multi-sig wallet when used in the two-step pattern.
 * 
 * An operator can be set by the owner on this token to manage token transfers on
 * behalf of the owner. 
 * 
 */
interface Singular {
    /*
     * When the curent owner has approved someone else as the next owner, subject
     * to acceptance or rejection. 
     */
    event Approved(address from, address to, uint expiry);
    /*
     * the ownership has been successfully transfered from A to B.
     */
    event Transferred(address from, address to, uint when, bytes32 note);

    /*
     * get the current owner
     */
    function currentOwner() view external returns (AssetOwner);
    
    /*
     * There can only be one approved receiver at a given time. This receiver cannot
     * be changed before the expiry time.
     * Can only be called by the token owner (in the form of OwnerOfSingulars account or 
     * the naked accoutn address associated with the currentowner) or an approved operator.
     * @param to address to be approved for the given token ID
     * @param expiry the dealline for the revceiver to the take the ownership
     * @param reason the reason for the transfer
     */
    function approveReceiver(AssetOwner to, uint expiry, bytes32 reason) external;

    /*
     * The approved account takes the ownership of this token. The caller must have
     * been set as the next owner of this token previously in a call by the current 
     * owner to the approve() function. The expiry time must be in the future
     * as of now. This function MUST call the sent() method on the original owner. 
     */
    function accept() external;
  
    /*
     * reject an offer. Must be called by the approved next owner(from the address 
     * of the OwnerOfSingulars or OwnerOfSingulars.ownerAddress()). 
     */
    function reject() external;
  
    /*
     * to send this token syncronously to an AssetOwner. It must call approveReceiver
     * first and invoke the "offer" function on the other AssetOwner. Setting the
     * current owner directly is not allowed.
     */ 
    function sendTo(AssetOwner to, bytes32 reason) external;
  

/// ownership history enumeration

    /*
     * To get the number of ownership changes of this token. 
     * @return the number of ownership records. The first record is the token genesis
     * record. 
     */
    function numOfTransfers() view external returns (uint256);
    /*
     * To get a specific transfer record in the format defined by implementation.
     * @param index the inde of the inquired record. It must in the range of 
     * [0, numberOfTransfers())
     */
    function getTransferAt(uint256 index) view external returns(string);
    
    /*
     * get all the transfer records in a serialized form that is defined by 
     * implementation.
     */
    function getTransferHistory() view external returns (string);

/// TODO: interface for hash locked swapping

}