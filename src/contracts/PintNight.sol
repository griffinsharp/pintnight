pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PintNight is Ownable {
    // to do: remove whatever you aren't using here
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeMath for uint16;
    using SafeMath for uint8;

    enum State { NOT_INITIATED, INVITE_PERIOD, AWAITING_EVENT, EVENT_PERIOD, COMPLETE }
    struct Event {
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
    }

    Event[] public events;

    mapping (uint => address) public eventToHost;
    mapping (uint => address[]) public eventToAttendees;
}