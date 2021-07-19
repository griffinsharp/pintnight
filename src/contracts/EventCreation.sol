pragma solidity ^0.8.0;

import "./PintNight.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EventCreation is PintNight {
    // To Do: add NatSpec comments
    // To Do: remove whatever you aren't using here
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;

    // EVENTS
    event NewEvent(
        uint eventId,
        string name,
        string location,
        uint256 date,
        address host
    );

    event UserInvited(
        uint eventId,
        string name,
        address host,
        address invited
    );

    event UserAccepted(

    );

    // Will want to edit this to include the results (how many attended the event and who won the pint "donation")
    event CompleteEvent(
        uint eventId,
        string name,
        string location,
        uint256 date,
        address host,
        address[] attendees
    );

    event PintWinner(

    );

    // VARS
    // $1.88 USD to $18.82 USD roughly.
    // UI should reccomend $5-10 USD in ether (avg pub beer price).
    // To Do: Can I save on uint amt here?
    uint256 minFee = 0.001 ether;
    uint256 maxFee = 0.01 ether;

    // MODIFIERS
    modifier onlyHost(uint _eventId) {
        require(msg.sender == eventToHost[_eventId], "Only the host of this event can call this function.");
        _;
    }

    modifier onlyAttendee(uint _eventId) {
        // The below may error out. Trying to shallow copy arr.
        // Memory arrs need a fixed length.
        bool memory isAttendee = false;
        address[] memory attendees = new address[](eventToAttendees[_eventId].length);
        attendees = eventToAttendees[_eventId];

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
        uint256 _date
    )
        public
        payable
    {
        require(msg.value >= minFee, "Escrow amount insufficient. Please increase its value.");
        require(msg.value <= maxFee, "Escrow amount too large. Please decrease its value.");

        // Non-named vars -- [created: now, state: 0]
        uint id = events.push(Event(_name, _location, _coordinates, now, _date, msg.value, State.NOT_INITIATED));
        eventToHost[id] = msg.sender;
        eventToAttendees[id] = eventToAttendees[id].push(msg.sender);
        emit NewEvent(id, _name, _location, _date, msg.sender);
    }

    // RECEIVE (if exists)

    // FALLBACK (if exists)

    // EXTERNAL
    function setMinFee(uint _newMinFee) external onlyOwner {
        minFee = _newMinFee;
    }

    function setMaxFee(uint _newMaxFee) external onlyOwner {
        maxFee = _newMaxFee;
    }

    // PUBLIC
    function inviteUser(uint _eventId, address _invited) public eventInvitePeriod(_eventId) onlyHost(_eventId) {
        eventToInvited[_eventId] = eventToInvited[_eventId].push(_invited);
        emit UserInvited(_eventId, events[_eventId].name, msg.sender, _invited);
    }

    function acceptInvitation(uint _eventId) public payable eventInvitePeriod(_eventId) onlyAttendee(_eventId) {
        require(msg.value == events[_eventId].fee, "Incorrect escrow amount. Please use the exact amount.");
        addAttendeeToEvent(_eventId, msg.sender);
    }

    // INTERNAL

    // PRIVATE

    // INTERNAL
    function addAttendeeToEvent(uint _id, address _attendee) internal onlyHost {
        eventToAttendees[_id] = eventToAttendees[_id].push(_attendee);
    }
}