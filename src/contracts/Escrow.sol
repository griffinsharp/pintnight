pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Escrow is Ownable {
    // to do: remove whatever you aren't using here
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;

    enum State { NOT_INITIATED, INVITE_PERIOD, AWAITING_EVENT, EVENT_PERIOD, COMPLETE }
    State public currentState;

    struct Event {
        string name;
        // time
        // location coordinates
        // fee
    }

    Event[] public events;

    // to do: Can prob make this more efficient
    mapping (uint => address) public eventToHost;
    mapping (uint => address[]) public eventToAttendees;

    uint public entryAmount;
    address host;
    // address payable public seller;

    // Modifiers
    modifier onlyHost(uint _eventId) {
        require(msg.sender == eventToHost[_eventId], "Only the host of this event can call this function.");
        _;
    }

    modifier onlyAttendee(uint _eventId) {
        bool memory isAttendee = false;
        address[] memory attendees = eventToAttendees[_eventId];
        for (uint i = 0; i < attendees.length; i++) {
            if (attendees[i] == msg.sender) {
                isAttendee = true;
            }
        }

        require(isAttendee, "Only an attendee of this event can call this function.");
        _;
    }

    modifier eventNotStarted() {
        require(currentState == State.NOT_INITIATED, 'Event has already been initiated.');
        _;
    }

    // Constructor
    // Use ownable constructor to set ownership to my address.
    // Use custom fuction to initiate contract details upon call from FE app.
    function initEvent() escrowNotStarted public  {
        // create event given user inputs
        // assign owner 
        if (msg.sender == )
        currentState = State.INVITE_PERIOD;
    }

    // Receive function (if exists)

    // Fallback function (if exists)

    // External

    // Public

    function initContract() escrowNotStarted public {
        if (msg.sender == buyer) { isBuyerIn = true; }
        if (msg.sender == seller) { isSellerIn = true; }
        if (isBuyerIn && isSellerIn) { currentState = State.AWAITING_PAYMENT; }
    }

    function deposit() onlyBuyer payable public {
        require(currentState == State.AWAITING_PAYMENT, 'Already paid.');
        require(msg.value == price, 'Wrong deposit amount.');
        currentState = State.AWAITING_DELIVERY;
    }

    function confirmDelivery() onlyBuyer payable public {
        require(currentState == State.AWAITING_DELIVERY, 'Cannot confirm delivery.');
        seller.transfer(price);
        currentState = State.COMPLETE;
    }

    function withdraw() onlyBuyer payable public {
        require(currentState == State.AWAITING_DELIVERY, 'Cannot withdrawal at this stage.');
        payable(msg.sender).transfer(price);
        currentState = State.COMPLETE;
    }

    function setFee() {

    }
    // Internal

    // Private
}