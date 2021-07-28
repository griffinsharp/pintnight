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

    // Will want to edit this to include the results (how many attended the event and who won the pint "donation")
    event SuccessfulEvent(
        uint256 eventId,
        string name,
        string location,
        uint256 date,
        address host,
        address[] attendees
    );

    event PintWinner(

    );

    event FailedEvent(
        string name,
        string location,
        uint256 eventDate,
        uint256 stateTransitionTime
    );

    // User checks in
    event CheckIn(
        string eventName,
        string location,
        address userAddress,
        uint256 checkInTime
    );

    event EventStarted(
        string eventName,
        string location,
        address userAddress,
        uint256 stateTransitionTime,
        uint256 eventDate
    );

    // VARS
    // Fee = escrow amount the host sets when creating the event.
    // $1.88 USD to $18.82 USD roughly.
    // UI should reccomend $5-10 USD in ether (avg pub beer price).
    // To Do: Can I save on uint amt here to smaller uint#?
    uint256 minFee = 0.001 ether;
    uint256 maxFee = 0.01 ether;

    // Percentage cut that PintNight takes on each member who joins.
    // Must be between 0-10,000. Originally set at 300, or 3%.
    uint256 operatingFeePercentage = 300;

    // MODIFIERS
    modifier onlyHost(uint _eventId) {
        require(msg.sender == eventToHost[_eventId], "Only the host of this event can call this function.");
        _;
    }

    modifier eventPeriod(uint _eventId) {
        require(events[_eventId].state == State.EVENT_PERIOD, 'It is not the event period.');
        _;
    }

    modifier eventPeriodOrComplete(uint _eventId) {
        State eventState = events[_eventId].state;
        require(eventState == State.EVENT_PERIOD || eventState == State.EVENT_COMPLETE, 'It is not the event or completed event period.');
        _;
    }

    modifier eventHasWinner(uint _eventId) {
        require(eventToWinner[_eventId] != 0x0, "Event does not have a pint winner yet.");
        _;
    }

    modifier onlyCheckedIn(uint _eventId) {
        // The below may error out. Trying to shallow copy arr.

        bool isCheckedIn = false;
        address[] memory checkedInUsers = new address[](eventToCheckedIn[_eventId].length);
        checkedInUsers = eventToCheckedIn[_eventId];

        for (uint i = 0; i < checkedInUsers.length; i++) {
            if (checkedInUsers[i] == msg.sender) {
                isCheckedIn = true;
            }
        }

        require(isCheckedIn, "Only a user who punctually checked-in to this event can call this function.");
        _;
    }

    // CONSTRUCTOR
    // Use custom fuction to initiate contract details upon call from FE app.
    // Hash _code on the frontend. Anyone who has code can join.
    function initEvent(
        bytes32 _code,
        string memory _name,
        string memory _location,
        uint256 _coordinates,
        uint256 _date
    )
        public
        payable
    {
        // Make sure event is in future. _date should be time in seconds after epoch.
        // block.timestamp - uint256 val in seconds since the epoch.
        require(_date < (block.timestamp + 52 weeks), "Date of event must not exceed 1 year from the present time.");
        require(_date >= (block.timestamp + 12 hours), "Date of event must be atleast 12 hours from the present time.");

        // Make sure the event join fee is a reasonable value.
        require(msg.value >= minFee, "Escrow amount insufficient. Please increase its value.");
        require(msg.value <= maxFee, "Escrow amount too large. Please decrease its value.");

        // Non-named vars -- [created: block.timestamp, state: 0]
        // block.timestamp is an alias for "now". "now" is dep.
        // Still want to show full fee. Other users will pay the same pre operatingFee.
        Event memory _event = Event({
            code: _code,
            name: _name,
            location: _location,
            coordinates: _coordinates,
            created: block.timestamp,
            date: _date,
            fee: msg.value,
            state: State.BEFORE_EVENT,
            result: Result.WAITING
        });

        events.push(_event);
        uint id = events.length.sub(1);

        // Attendance
        eventToHost[id] = msg.sender;
        _addAttendeeToEvent(id, msg.sender);

        // Accounting
        _eventAccounting(id, msg.value);

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

    // This can only be called by function owner.
    // Instead of charging the user to transfer our % cut (pay more gas), we just keep track of the fees we've accrued.
    // Users pay 3% of the event fee upon joining or creating an event.
    function withdrawFees() external onlyOwner {
        require(address(this).balance > totalOperatingFees, "Contract balance insufficient.");
        payable(owner()).transfer(totalOperatingFees);
        totalOperatingFees = 0;
    }

    function setOperatingFeePercentage(uint _percentage) external onlyOwner {
        require(_percentage >= 0 && _percentage <= 10000, "Invalid operating fee percentage.");
        operatingFeePercentage = _percentage;
    }

    // PUBLIC

    // Called by those who actually attended the event.
    // 1.) Event has a winner. This means decideWinner has been called and event is in COMPLETE.
    // 2.) Caller has checked-in.
    function withdrawEventFee(uint _eventId) public eventHasWinner(_eventId) onlyCheckedIn(_eventId) {

        // If you are winner, get initial deposit back + deposit*(eventToAttendees - eventToCheckedIn)
        // If not, just get initial deposit back.
    }

    function decideWinner(uint _eventId) public eventPeriodOrComplete(_eventId) onlyCheckedIn(_eventId) {
        // Check if winner is default address (winner not selected yet)
        require(eventToWinner[_eventId] == 0x0, "Winner already assigned.");

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
            emit PintWinner();
        }

    }

    // PRIVATE

    // INTERNAL
    function _addAttendeeToEvent(uint _eventId, address _attendee) internal {
        eventToAttendees[_eventId].push(_attendee);
    }

    // Keeps track of how much attendees have paid towards the event and operating fees paid.
    function _eventAccounting(uint _eventId, uint _feePaid) internal {
        uint calculatedPercentage = operatingFeePercentage.div(10000);
        uint256 operatingFee = _feePaid.mul(calculatedPercentage);
        uint256 remainingBalance = _feePaid.sub(operatingFee);

        totalOperatingFees.add(operatingFee);
        eventToBalance[_eventId] = eventToBalance[_eventId].add(remainingBalance);
    }
}