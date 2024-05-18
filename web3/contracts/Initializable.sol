// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Importing the Address library
import "./Address.sol";

// Abstract contract defining initialization behavior
abstract contract Initializable {
    uint8 private _initialized; // Internal variable to track initialization status
    bool private _initializing; // Internal variable to track initialization state

    // Event emitted when the contract is initialized
    event Initialized(uint8 version);

    // Modifier to enforce initialization behavior
    modifier initializer() {
        // Check if the call is a top-level call and the contract is not already initialized
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable contract is already initialized"
        );
        _initialized = 1; // Mark the contract as initialized
        if (isTopLevelCall) {
            _initializing = true; // Set the contract to be initializing if it's a top-level call
        }
        _; // Execute the function body
        if (isTopLevelCall) {
            _initializing = false; // Reset the initializing state if it's a top-level call
            emit Initialized(1); // Emit an event indicating initialization
        }
    }

    // Modifier to enforce reinitialization behavior with a specified version
    modifier reinitializer(uint8 version) {
        // Check if the contract is not currently initializing and is not already initialized with a higher version
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version; // Mark the contract as initialized with the specified version
        _initializing = true; // Set the contract to be initializing
        _; // Execute the function body
        _initializing = false; // Reset the initializing state
        emit Initialized(version); // Emit an event indicating initialization with the specified version
    }

    // Modifier to restrict a function to only be callable during initialization
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _; // Execute the function body
    }

    // Internal function to disable initializers after initialization
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max; // Mark the contract as initialized with the maximum version
            emit Initialized(type(uint8).max); // Emit an event indicating initialization with the maximum version
        }
    }
}
