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

    modifier onlyInvitee(uint _eventId) {
        // The below may error out. Trying to shallow copy arr.
        // Memory arrs need a fixed length.
        bool isInvitee = false;
        address[] memory invitees = new address[](eventToInvitees[_eventId].length);
        invitees = eventToInvitees[_eventId];

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
    // Anyone who has code can join, so keep it secret!
    // We never want to expose our actual input and convert to hash afterwards inside the contract.
    // Hash on the frontend with web3. Call function. Compare hashes.
    // NEED: 1.) Invite period 2.) Correct join code 3.) Correct msg.value
    function joinEventByInviteCode(uint _eventId, bytes32 _inviteCode) public payable eventInvitePeriod(_eventId) {
        require(_inviteCode == events[_eventId].code, "Incorrect join code.");
        require(msg.value == events[_eventId].fee, "Incorrect escrow amount. Please use the exact amount specified.");

        _eventAccounting(_eventId, msg.value);
        _addAttendeeToEvent(_eventId, msg.sender);
        emit UserJoined(_eventId, events[_eventId].name, msg.sender, eventToAttendees[_eventId], true);
    }



    // INTERNAL

    // PRIVATE

    // (normal/view/pure order within groupings)

}