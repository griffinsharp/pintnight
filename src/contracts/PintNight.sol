pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PintNight is Ownable {
    // to do: remove whatever you aren't using here
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;
    using SafeMath for uint8;

    // Event state
    enum State { BEFORE_EVENT, EVENT_PERIOD, EVENT_COMPLETE }

    // Result of event
    // Waiting for event to start, success (1+ checked-in), or failure (no one checked-in on time).
    enum Result { WAITING, SUCCESS, FAIL }

    struct Event {
        bytes32 code;
        string name;
        // State - 0 to 4 enum
        // Want to eventually compare relative location for privacy concerns.
        // Name or location. Exact coordinates for comparison.
        string location;
        uint256 coordinates;
        uint256 created;
        uint256 date;
        uint256 fee;
        State state;
        Result result;
    }

    uint totalOperatingFees;
    Event[] public events;

    mapping (uint => address[]) internal eventToAttendees;
    mapping (uint => uint) internal eventToBalance;
    mapping (uint => address) internal eventToHost;
    mapping (uint => address[]) internal eventToInvitees;
}

// Need to call contract once per day at certain time to transition events to a failure, if applicable.
// Functions on the SC need to be called somehow.
// So, if none of the attendeees check-in on time AND none attempt to check-in after the check-in period...
// ...will have to do this state transition manually via a call to an onlyOwner transitionFailedEvents fn.