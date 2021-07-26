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

    // Will want to edit this to include the results (how many attended the event and who won the pint "donation")
    event CompleteEvent(
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

    );

    // User checks in
    event checkIn(
        string eventName,
        string location,
        address userAddress,
        uint256 checkInTime
    );

    event eventStarted(
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
    // To Do: Can I save on uint amt here?
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

    modifier eventInvitePeriod(uint _eventId) {
        require(events[_eventId].state == State.BEFORE_EVENT, 'It is not the event invite period.');
        _;
    }

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

    // NEED: 1.) Invite Period 2.) Be Attendee 3.) Correct time (be after event date to (date + 30 mins))
    // Worth noting that both the timestamp and the block hash can be influenced by miners to some degree.
    // Realistically, abuse isn't really practical here given the nature of our app.
    function rollCall(uint _eventId) external eventInvitePeriod(_eventId) onlyAttendee(_eventId) {
        Event storage ourEpicEvent = events[_eventId];
        uint currentTime = block.timestamp;
        uint upperCheckinTime = ourEpicEvent.date.add(30 minutes);
        require(ourEpicEvent.date >= currentTime, "Event has not yet started. Try checking in again later.");

        if (currentTime <= upperCheckinTime) {
            ourEpicEvent.state = State.EVENT_PERIOD;
            emit eventStarted(ourEpicEvent.name, ourEpicEvent.location, msg.sender, block.timestamp, ourEpicEvent.date);
            emit checkIn(ourEpicEvent.name, ourEpicEvent.location, msg.sender, block.timestamp);
        } else {
            ourEpicEvent.state = State.EVENT_COMPLETE;
        }
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