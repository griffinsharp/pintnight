FN ORDER
// CONSTRUCTOR
// RECEIVE (IF EXISTS)
// FALLBACK (IF EXISTS)
// EXTERNAL
// PUBLIC
// INTERNAL
// PRIVATE
// (normal/view/pure order within groupings)

FN VISIBILITY ORDER
// Visibility
// Mutability
// Virtual
// Override
// Custom modifiers

function thisFunctionNameIsReallyLong(address x, address y, address z)
    public
    onlyOwner
    priced
    returns (address)
{
    doSomething();
}

function thisFunctionNameIsReallyLong(
    address x,
    address y,
    address z,
)
    public
    onlyOwner
    priced
    returns (address)
{
    doSomething();
}

function thisFunctionNameIsReallyLong(
    address a,
    address b,
    address c
)
    public
    returns (
        address someAddressName,
        uint256 LongArgument,
        uint256 Argument
    )
{
    doSomething()

    return (
        veryLongReturnArg1,
        veryLongReturnArg2,
        veryLongReturnArg3
    );
}