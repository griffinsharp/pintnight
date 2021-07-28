pragma solidity ^0.8.0;

import "./EventInvite.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract EventCheckIn is EventInvite  {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;

    modifier onlyAttendee(uint _eventId) {
        // The below may error out. Trying to shallow copy arr.
        // Memory arrs need a fixed length.
        // Know if they are host, they are definitely an attendee.
        bool isAttendee = false;
        if (eventToHost[_eventId] == msg.sender) {
            isAttendee = true;
        } else {
            address[] memory attendees = new address[](eventToAttendees[_eventId].length);
            attendees = eventToAttendees[_eventId];

            for (uint i = 0; i < attendees.length; i++) {
                if (attendees[i] == msg.sender) {
                    isAttendee = true;
                }
            }
        }

        require(isAttendee, "Only an attendee of this event can call this function.");
        _;
    }

    // RECEIVE (IF EXISTS)
    // FALLBACK (IF EXISTS)
    // EXTERNAL
    // PUBLIC

    function checkInForEvent(uint _eventId) public eventPeriod(_eventId) onlyAttendee(_eventId) {
        Event storage ourEpicEvent = events[_eventId];
        uint upperCheckinTime = ourEpicEvent.date.add(15 minutes);

        if (block.timestamp <= upperCheckinTime) {
            _addAttendeeToCheckedIn(_eventId, msg.sender);
            emit CheckIn(ourEpicEvent.name, ourEpicEvent.location, msg.sender, block.timestamp);
        } else {
            _markEventFailed(ourEpicEvent);
        }
    }

    // NEED: 1.) Invite Period 2.) Be Attendee 3.) Correct time (be after event date to (date + 15 mins))
    // Worth noting that both the timestamp and the block hash can be influenced by miners to some degree.
    // Realistically, abuse isn't really practical here given the nature of the app and amt of Ether involved.
    function rollCall(uint _eventId) public eventInvitePeriod(_eventId) onlyAttendee(_eventId) {
        Event storage ourEpicEvent = events[_eventId];
        uint upperCheckinTime = ourEpicEvent.date.add(15 minutes);

        // checkInForEvent is only able to be called during the event. This is called when the state is BEFORE_EVENT.
        // Need to check to make sure it's not being called prematurely.
        require(ourEpicEvent.date >= block.timestamp, "Event has not yet started. Try checking in again later.");

        // Now we know user is not too early, make sure they are not too late.
        // If they are within the acceptable window, start event and check-in. If they are not, mark event failed.
        if (block.timestamp <= upperCheckinTime) {
            ourEpicEvent.state = State.EVENT_PERIOD;
            ourEpicEvent.result = Result.SUCCESS;
            _addAttendeeToCheckedIn(_eventId, msg.sender);

            emit EventStarted(ourEpicEvent.name, ourEpicEvent.location, msg.sender, block.timestamp, ourEpicEvent.date);
            emit CheckIn(ourEpicEvent.name, ourEpicEvent.location, msg.sender, block.timestamp);
        } else {
            _markEventFailed(ourEpicEvent);
        }
    }

    // INTERNAL
    function _addAttendeeToCheckedIn(uint _eventId, address _attendee) internal {
        eventToCheckedIn[_eventId].push(_attendee);
    }

    // PRIVATE

    function _markEventFailed(Event storage _event) private {
        _event.state = State.EVENT_COMPLETE;
        _event.result = Result.FAIL;
        emit FailedEvent(_event.name, _event.location, _event.date, block.timestamp);
    }


    // (normal/view/pure order within groupings)

}