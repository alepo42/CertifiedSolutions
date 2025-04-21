// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KnapsackValidator {
    event SolutionFound(uint256, uint256);

    // Address of contract owner
    address owner;

    // Structure to represent an object
    struct Item {
        uint256 weight;
        uint256 value;
    }

    // Array of available items
    Item[] public items;

    // Maximum knapsack capacity
    uint256 public maxWeight;

    // Structure to represent a solution
    struct BestSolution {
       uint256[] solutionItems;
       uint256 solutionValue;
       uint256 solutionWeight;
       uint256 timestamp;
       address senderAddress;
    }

    // History of best solutions
    BestSolution[] public historyOfBestSolutions;

    // Boolean flag that indicates whether it is possible to submit solutions
    bool submissionsOpen;

    // Constructor to initialize objects and maximum capacity
    constructor(uint256 _maxWeight, Item[] memory _items) {
        maxWeight = _maxWeight;
        for (uint256 i = 0; i < _items.length; i++) {
            items.push(_items[i]);
        }
        // Set the address of the owner
        owner = msg.sender;
        // Initially, submissions are open
        submissionsOpen = true;
    }

    // Function to get the details of the instance
    function getInstance() public view returns (Item[] memory, uint256) {
        return (items, maxWeight);
    }

    // Function to check the validity of the proposed solution
    function checkValidity(uint256[] memory _solution) public view returns (bool, uint256, uint256) {
        uint256 totalWeight = 0;
        uint256 totalValue = 0;

        // All the indices of the proposed solution must be different
        // Otherwise, return false
        for (uint256 i = 0; i < _solution.length; i++) {
            for (uint256 j = i+1; j < _solution.length; j++) {
                if (_solution[i] == _solution[j]) {
                    return (false, 0, 0);
                }
            }
        }
        // Computes the total weight and value of the proposed solution
        for (uint256 i = 0; i < _solution.length; i++) {
            // If one of the indices is not valid, return false
            if (_solution[i] >= items.length) {
                return (false, 0, 0);
            }
            totalWeight += items[_solution[i]].weight;
            totalValue += items[_solution[i]].value;
        }
        // If the total weight exceeds maximum capacity, return false
        if (totalWeight > maxWeight) {
            return (false, 0, 0);
        }
        // At this point, we have a valid solution, and we return its total value 
        // and weight
        return (true, totalValue, totalWeight);
    }

    // Function for submitting a solution
    function submitSolution(uint256[] memory _solution) public returns (bool) {
        // Proceeds only if submissions are open
        if (! submissionsOpen) {
            return (false);
        }
        // Check whether the submitted solution is valid
        // If so, it computes also its total value
        (bool isValid, uint256 totalValue, uint256 totalWeight) = checkValidity(_solution);
        // If the solution is not valid, return false
        if (! isValid) {
            return (false);
        }
        // Looks in the history for the best solution found so far
        uint256 bestTotalValue = 0;
        if (historyOfBestSolutions.length > 0) {
            bestTotalValue = historyOfBestSolutions[historyOfBestSolutions.length - 1].solutionValue;
        }
        // If the submitted solution is the first one, or if it is better than
        // the best solution found so far
        if (totalValue > bestTotalValue) {
            // Save the submitted solution in the contract state
            historyOfBestSolutions.push(BestSolution({
                solutionItems: _solution,
                solutionValue: totalValue,
                solutionWeight: totalWeight,
                timestamp: block.timestamp,
                senderAddress: msg.sender
            }));
            // Emit an event indicating that a new better solution has been found
            emit SolutionFound(totalValue, totalWeight);
            // Return true, indicating that a better solution has been added
            return (true);
        }
        else {
            // Otherwise, do not save the submitted solution and return false
            return (false);
        }
    }

    // Function to get the number of solutions stored in the contract
    function getNumberOfSolutions() public view returns (uint256) {
        return (historyOfBestSolutions.length);
    }

    // Function to get a specified solution stored in the contract
    function getStoredSolution(uint256 _index) public view returns (bool, BestSolution memory) {
        BestSolution memory emptySolution = BestSolution(new uint256[](0), 0, 0, 0, address(0));
        // If the specified index is out of range, return false
        if (_index >= historyOfBestSolutions.length) {
            return (false, emptySolution);
        }
        return (true, historyOfBestSolutions[_index]);
    }

    // Function to get the best solution found so far
    function getBestSolution() public view returns (bool, BestSolution memory) {
        BestSolution memory emptySolution = BestSolution(new uint256[](0), 0, 0, 0, address(0));
        // If there are no solutions stored in the contract, return false
        if (historyOfBestSolutions.length == 0) {
            return (false, emptySolution);
        }
        return (true, historyOfBestSolutions[historyOfBestSolutions.length - 1]);
    }

    // Function to close the possibility to submit solutions
    function closeSubmissions() public {
        require(msg.sender == owner, "Only the owner of the contract can call this function");
        submissionsOpen = false;
    }

    // Function to see if submissions are open
    function areSubmissionsOpen() public view returns (bool) {
        return (submissionsOpen);
    }
}
