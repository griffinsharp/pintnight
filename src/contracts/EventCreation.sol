pragma solidity ^0.8.0;

import "./PintNight.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EventCreation is PintNight {
    // to do: add NatSpec comments
    // to do: remove whatever you aren't using here
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;

    // EVENTS
    event NewEvent(uint eventId, string name, string location, uint256 date, address host);
    // Will want to edit this to include the results (how many attended the event and who won the pint "donation")
    event CompleteEvent(uint eventId, string name, string location, uint256 date, address host, address[] attendees);
    event PintWinner();

    // VARS
    // $1.88 USD to $18.82 USD roughly.
    // UI should reccomend $5-10 USD in ether (avg pub beer price).
    uint minFee = 0.001 ether;
    uint maxFee = 0.01 ether;

    // MODIFIERS
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

    modifier eventInvitePeriod(uint _eventId) {
        require(events[_eventId].state == State.INVITE_PERIOD, 'It is not the event invite period.');
        _;
    }

    // CONSTRUCTOR
    // Use ownable constructor to set ownership to my address.
    // Use custom fuction to initiate contract details upon call from FE app.
    function initEvent(
        string _name,
        string _location,
        uint256 _coordinates,
        uint256 _date,
        uint256 _fee
    )
        public
    {
        require(_fee >= minFee, "Fee amount insufficient. Increase fee amount.");
        require(_fee <= maxFee, "Fee amount too large. Decrease fee amount.");

        // Non-named vars -- [created: now, state: 0]
        uint id = events.push(Event(_name, _location, _coordinates, now, _date, _fee, State.NOT_INITIATED));
        eventToHost[id] = msg.sender;
        eventToAttendees[id] = eventToAttendees[id].push(msg.sender);
        emit NewEvent(id, _name, _location, _date, msg.sender);
    }

    // RECEIVE (if exists)

    // FALLBACK (if exists)

    // EXTERNAL (normal/view/pure ordering)

    // PUBLIC

    // INTERNAL

    // PRIVATE
    function inviteUser() eventInvitePeriod public payable {

    }

    function changeFee() external onlyOwner {

    }

    function deposit() onlyHost payable public {
        require(currentState == State.AWAITING_PAYMENT, 'Already paid.');
        require(msg.value == price, 'Wrong deposit amount.');
        currentState = State.AWAITING_DELIVERY;
    }

    function confirmDelivery() onlyHost payable public {
        require(currentState == State.AWAITING_DELIVERY, 'Cannot confirm delivery.');
        seller.transfer(price);
        currentState = State.COMPLETE;
    }

    function withdraw() onlyHost payable public {
        require(currentState == State.AWAITING_DELIVERY, 'Cannot withdrawal at this stage.');
        payable(msg.sender).transfer(price);
        currentState = State.COMPLETE;
    }

    function setMinFee() external onlyOwner {

    }

    function setMaxFee() external onlyOwner {

    }

    // INTERNAL
    function addAttendeeToEvent(uint _id, address _attendee) internal onlyHost {
        eventToAttendees[_id] = eventToAttendees[_id].push(_attendee);
    }
}