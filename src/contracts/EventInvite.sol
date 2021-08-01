pragma solidity ^0.8.0;

import "./EventCreation.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EventInvite is EventCreation {

    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;

    // EVENTS
    event UserInvited(
        uint256 eventId,
        string name,
        address host,
        address invited
    );

    // Either accepted invite or used join code.
    event UserJoined(
        uint256 eventId,
        string name,
        address acceptedUser,
        address[] attendees,
        bool joinedByCode
    );

    // MODIFIERS
    modifier eventInvitePeriod(uint _eventId) {
        require(events[_eventId].state == State.BEFORE_EVENT, 'It is not the event invite period.');
        _;
    }

    modifier onlyHost(uint _eventId) {
        require(msg.sender == eventToHost[_eventId], "Only the host of this event can call this function.");
        _;
    }

    modifier onlyInvitee(uint _eventId) {
        // The below may error out. Trying to shallow copy arr.
        // Memory arrs need a fixed length.
        bool isInvitee = false;
        address[] memory invitees = eventToInvitees[_eventId];

        for (uint i = 0; i < invitees.length; i++) {
            if (invitees[i] == msg.sender) {
                isInvitee = true;
            }
        }

        require(isInvitee, "Only an invitee of this event can call this function.");
        _;
    }

    // RECEIVE (IF EXISTS)

    // FALLBACK (IF EXISTS)

    // EXTERNAL

    // PUBLIC
    // NEED: 1.) Invite period 2.) Be Invitee 3.) Correct msg.value 4.) Accounting 5.) Add attendee 6.) emit event
    function acceptInvitation(uint _eventId) public payable eventInvitePeriod(_eventId) onlyInvitee(_eventId) {
        require(msg.value == events[_eventId].fee, "Incorrect escrow amount. Please use the exact amount specified.");

        _eventAccounting(_eventId, msg.value);
        _addAttendeeToEvent(_eventId, msg.sender);
        emit UserJoined(_eventId, events[_eventId].name, msg.sender, eventToAttendees[_eventId], false);
    }

    // NEED: 1.) Invite Period 2.) Be Host
    function inviteUser(uint _eventId, address _invited) public eventInvitePeriod(_eventId) onlyHost(_eventId) {
        eventToInvitees[_eventId].push(_invited);
        emit UserInvited(_eventId, events[_eventId].name, msg.sender, _invited);
    }

    // Users can also join events if they have the correct join code without being invited first.
    // Though we hash before we store the password, the first user who enters the passcode will reveal it.
    // This is more of a UX feature to safeguard against users accidentally signing up for the wrong event.
    // Because of this, we also check if the user is an invitee of the event. That way, not just anyone can use the password once revealed.
    // NEED: 1.) Invite period 2.) Is an Invitee 3.) Correct join code 4.) Correct msg.value
    function joinEventByInviteCode(uint _eventId, bytes32 _inviteCode) public payable eventInvitePeriod(_eventId) onlyInvitee(_eventId) {
        require(_inviteCode == events[_eventId].code, "Incorrect join code.");
        require(msg.value == events[_eventId].fee, "Incorrect escrow amount. Please use the exact amount specified.");

        _eventAccounting(_eventId, msg.value);
        _addAttendeeToEvent(_eventId, msg.sender);
        emit UserJoined(_eventId, events[_eventId].name, msg.sender, eventToAttendees[_eventId], true);
    }


    // INTERNAL
    // PRIVATE

}