pragma solidity ^0.4.0;

import "./Proxy.sol";
import "./BaseData.sol";

//not finish yet, will move Storage level common functions to a global smart contract
contract Storage is Proxy, BaseData{
    constructor() public{
    }

    function setLogicAddress(bytes32 _version, address _delegateTo)public {
        setAddress(_version,_delegateTo);
    }

    function setLogicAddressAndActivate(bytes32 _version, address _delegateTo) public {
        setAddress(_version,_delegateTo);
        setCurrent(_version);
    }


    function deleteLogicAddress(bytes32 _version) public {
        deleteAddress(_version);
    }

    function hasLogicAddress(bytes32 _version) public view returns(bool){
        address logic= getAddress(_version);
        if(logic != address(0x00)){
            return true;
        }
        return false;
    }

    function activateLogic(bytes32 _version) public {
        address logic = getAddress(_version);
        require(logic != address(0x00),"you must register the version and its logic address first");
        setCurrent(_version);
    }

    function currentLogicAddress() view public returns (address){
        bytes32 version = getCurrent();
        return getAddress(version);
    }

}