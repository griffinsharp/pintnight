pragma solidity ^0.8.0;

import "./EventCheckIn.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract EventFinish is EventCheckIn  {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;

    // EVENTS
    event PintWinner(
        string eventName,
        address userAddress
    );

    // VARS
    uint randNonce = 0;

    // MODIFIERS
    modifier eventPeriodOrComplete(uint _eventId) {
        State eventState = events[_eventId].state;
        require(eventState == State.EVENT_PERIOD || eventState == State.EVENT_COMPLETE, 'It is not the event or completed event period.');
        _;
    }

    modifier hasWinner(uint _eventId) {
        require(eventToWinner[_eventId] != address(0), "Event does not have a pint winner yet.");
        _;
    }

    modifier noWinner(uint _eventId) {
        require(eventToWinner[_eventId] == address(0), "Event already has a winner.");
        _;
    }

    modifier onlyCheckedIn(uint _eventId) {
        // The below may error out. Trying to shallow copy arr.

        bool isCheckedIn = false;
        address[] memory checkedInUsers = eventToCheckedIn[_eventId];

        for (uint i = 0; i < checkedInUsers.length; i++) {
            if (checkedInUsers[i] == msg.sender) {
                isCheckedIn = true;
            }
        }

        require(isCheckedIn, "Only a user who punctually checked-in to this event can call this function.");
        _;
    }

    // Prevents a user from calling the payout function multiple times
    modifier onlyUnpaid(uint _eventId) {
        bool hasNotBeenPaid = true;
        address[] memory paidUsers = eventToPaidOut[_eventId];

        if (paidUsers.length != 0) {
            for (uint i = 0; i < paidUsers.length; i++) {
                if (paidUsers[i] == msg.sender) {
                    hasNotBeenPaid = false;
                }
            }
        }

        require(hasNotBeenPaid, "Only a user who punctually checked-in to this event can call this function.");
        _;
    }

    // CONSTRUCTOR
    // RECEIVE (IF EXISTS)
    // FALLBACK (IF EXISTS)
    // EXTERNAL

    // PUBLIC
    function decideWinner(uint _eventId) public eventPeriodOrComplete(_eventId) noWinner(_eventId) onlyCheckedIn(_eventId) {
        Event storage ourEpicEvent = events[_eventId];
        uint upperCheckinTime = ourEpicEvent.date.add(15 minutes);

        // Possible to NOT have transitioned to COMPLETE just yet, so check time.
        if (block.timestamp > upperCheckinTime) {
            if (ourEpicEvent.state == State.EVENT_PERIOD) {
                ourEpicEvent.state = State.EVENT_COMPLETE;
            }

            // rand should be a pseudo random number the length of the chekedIn array - 1 (last index).
            uint256 rand = _getRandomNum(eventToCheckedIn[_eventId].length);
            address winner = eventToCheckedIn[_eventId][rand];
            eventToWinner[_eventId] = winner;
            emit PintWinner(ourEpicEvent.name, winner);
        }

    }

    // Called by those who actually attended the event.
    // 1.) Event has a winner. This means decideWinner has been called and event is in COMPLETE.
    // 2.) Caller has checked-in.
    // 3.) User has not been paid yet
    function withdrawEventFee(uint _eventId) public hasWinner(_eventId) onlyCheckedIn(_eventId) onlyUnpaid(_eventId) {
        address winnerAddress = eventToWinner[_eventId];
        Event memory epicEvent = events[_eventId];

        uint256 amtUserPaidPostFees = epicEvent.fee.sub(epicEvent.fee.mul(operatingFeePercentage.div(10000)));

        if (eventToCheckedIn[_eventId].length == 1) {
            // Since there is a winner, only one person checked in, tranfer them the whole balance.
            // Require statement is just a safeguard.
            require(msg.sender == winnerAddress, "You should be the user who won the pint if you've made it this far...");

            uint256 totalEventBal = eventToBalance[_eventId];
            eventToBalance[_eventId] = 0;
            eventToPaidOut[_eventId].push(winnerAddress);

            payable(winnerAddress).transfer(totalEventBal);
        } else if (eventToCheckedIn[_eventId].length == eventToAttendees[_eventId].length) {
            // Know checkedIn is not 0 (hasWinner) or 1 (above conditional). Check if everyone checked in to attend the event.
            if (winnerAddress == msg.sender) {
                uint256 userWinnings = amtUserPaidPostFees.mul(2);
                _payOutUser(_eventId, userWinnings);
            } else {
                // If they're not winner, need to count for the fact that user wins a free pint from everyone else (-1).
                uint256 userWinnings = amtUserPaidPostFees - (amtUserPaidPostFees.div((eventToAttendees[_eventId].length - 1)));
                _payOutUser(_eventId, userWinnings);
            }
        } else {
            // Know it's not 0, 1, or the same number, so attendees > checked in. Those who did not check-in, lose deposit.
            // Those who checked-in, but did not win get their deposit back.
            // User who won gets the deposits of those who did not show up.
            if (winnerAddress == msg.sender) {
                // Get all the attendees who did not checkIn + initial deposit
                uint256 noShowAmt = (eventToAttendees[_eventId].length.sub(eventToCheckedIn[_eventId].length));
                uint256 userWinnings = amtUserPaidPostFees + amtUserPaidPostFees.mul(noShowAmt);
                _payOutUser(_eventId, userWinnings);
            } else {
                // Get just initial deposit if attended
                uint256 userWinnings = amtUserPaidPostFees;
                _payOutUser(_eventId, userWinnings);
            }
        }
    }

    // INTERNAL
    // PRIVATE
    function _getRandomNum(uint _numberOfUsers) private returns(uint) {
        randNonce = randNonce.add(1);
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _numberOfUsers;
    }

    function _payOutUser(uint _eventId, uint _userWinnings) private {
        eventToBalance[_eventId] = eventToBalance[_eventId].sub(_userWinnings);
        eventToPaidOut[_eventId].push(msg.sender);
        payable(msg.sender).transfer(_userWinnings);
    }
}