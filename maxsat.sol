// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MaxSATValidator {
    event SolutionFound(uint256);

    // Address of contract owner
    address owner;

    // Array to represent a formula, that is, a list of clauses. Each clause is a list
    // of literals. Each literal is a number in the range [1..n] if it is a variable,
    // or in the range [-n..-1] if it is a negated variable
    int256[][] public formula;

    // The number of variables that compose the formula
    uint256 public numberOfVariables;

    // Structure to represent a solution
    struct BestSolution {
       uint256[] assignment;
       uint256 numberOfSatisfiedClauses;
       uint256 timestamp;
       address senderAddress;
    }

    // History of best solutions
    BestSolution[] public historyOfBestSolutions;

    // Boolean flag that indicates whether it is possible to submit solutions
    bool submissionsOpen;

    // Constructor to set the lists of clauses and the number of variables
    // contained in the formula
    constructor(int256[][] memory _clauses) {
        uint256 numVariables = 0;
        uint256 variable = 0;
        for (uint256 i = 0; i < _clauses.length; i++) {
            formula.push(_clauses[i]);
            for (uint256 j = 0; j < _clauses[i].length; j++) {
                variable = uint256(_clauses[i][j] >= 0 ? _clauses[i][j] : - _clauses[i][j]);
                if (variable > numVariables) {
                    numVariables = variable;
                }
            }
        }
        // Set the number of variables contained in the formula
        numberOfVariables = numVariables;
        // Set the address of the owner
        owner = msg.sender;
        // Initially, submissions are open
        submissionsOpen = true;
    }

    // Function to get the details of the instance: the list of clauses,
    // and the number of variables
    function getInstance() public view returns (int256[][] memory, uint256) {
        return (formula, numberOfVariables);
    }

    // Function to check the validity of the proposed solution
    function checkValidity(uint256[] memory _solution) public view returns (bool) {
        // The number of values in the assignment must be the same as the number
        // of variables
        if (_solution.length != numberOfVariables) {
            return (false);
        }
        // Each element in the assignment must be 0 or 1
        for (uint256 i = 0; i < _solution.length; i++) {
            if (_solution[i] != 0 && _solution[i] != 1) {
                return (false);
            }
        }
        // At this point, we have a valid solution, so we return true
        return (true);
    }

    // Function for submitting a solution
    function submitSolution(uint256[] memory _solution) public returns (bool) {
        // Proceeds only if submissions are open
        if (! submissionsOpen) {
            return (false);
        }
        // Check whether the submitted solution is valid
        (bool isValid) = checkValidity(_solution);
        // If the solution is not valid, return false
        if (! isValid) {
            return (false);
        }
        // Compute the number of satisfied clauses
        uint256 satisfiedClauses = 0;
        bool clauseSatisfied;
        int256 literal;
        uint256 variable;
        for (uint256 i = 0; i < formula.length; i++) {
            // Consider the i-th clause of the instance
            clauseSatisfied = false;
            // For each literal
            for (uint256 j = 0; j < formula[i].length && !clauseSatisfied; j++) {
                literal = formula[i][j];
                variable = uint256(literal >= 0 ? literal : -literal) - 1;
                // Check whether the assignment satisfies this literal
                if ((literal > 0 && _solution[variable] == 1) ||
                    (literal < 0 && _solution[variable] == 0)) {
                    clauseSatisfied = true;
                }
            }
            // If the current clause is satisfied, increment the number of
            // satisfied clauses
            if (clauseSatisfied) {
                satisfiedClauses++;
            }
        }
        // Looks in the history for the best solution found so far
        uint256 bestStoredValue = 0;
        if (historyOfBestSolutions.length > 0) {
            bestStoredValue = historyOfBestSolutions[historyOfBestSolutions.length - 1].numberOfSatisfiedClauses;
        }
        // If the submitted solution is the first one, or if it is better than
        // the best solution found so far
        if (satisfiedClauses > bestStoredValue) {
            // Save the submitted solution in the contract state
            historyOfBestSolutions.push(BestSolution({
                assignment: _solution,
                numberOfSatisfiedClauses: satisfiedClauses,
                timestamp: block.timestamp,
                senderAddress: msg.sender
            }));
            // Emit an event indicating that a new better solution has been found
            emit SolutionFound(satisfiedClauses);
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
        BestSolution memory emptySolution = BestSolution(new uint256[](0), 0, 0, address(0));
        // If the specified index is out of range, return false
        if (_index >= historyOfBestSolutions.length) {
            return (false, emptySolution);
        }
        return (true, historyOfBestSolutions[_index]);
    }

    // Function to get the best solution found so far
    function getBestSolution() public view returns (bool, BestSolution memory) {
        BestSolution memory emptySolution = BestSolution(new uint256[](0), 0, 0, address(0));
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
